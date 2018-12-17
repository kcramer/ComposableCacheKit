//
//  DiskCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 2/18/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import os.log
import Promise

/**
 A cache for Data objects indexed by a String key and stored on the filesystem.
 A size limit can be placed on the cache but since it is stored in the caches
 folder the OS may also remove items as needed to free space.
 */
public final class DiskCache: Cache {
    public typealias Key = String
    public typealias Value = Data
    private let logSubsystem: String
    private static let HoursPerDay: Double = 60 * 60 * 24
    private let manager: FileManager
    private let path: String
    private let limit: UInt64
    private var size: UInt64 = 0
    private lazy var basePath: URL? = {
        let url = try? self.manager.url(for: .cachesDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: true)
        return url?.appendingPathComponent(self.path)
    }()
    private lazy var logger: OSLog = {
        return OSLog(subsystem: logSubsystem, category: "diskcache")
    }()
    private lazy var queue: DispatchQueue = {
        let label = FrameworkConstants.identifier + ".diskcache." +
            (self.basePath?.lastPathComponent ?? "")
        return DispatchQueue(label: label, attributes: [.concurrent])
    }()

    private func logOnError<T>(_ operation: String, action: () throws -> T) -> T? {
        do {
            return try action()
        } catch let err {
            os_log("Failed '%@' with error: %@",
                   log: logger, type: .error,
                   operation, String(describing: err))
            return nil
        }
    }

    /**
     Create a `DiskCache`.
     - parameter path: The filesystem path to use for the cache. This is
        appended to the path for the user's caches directory to form a full path.
     - parameter logSubsystem: The subsystem name to use for logging.  Usually
        a reverse DNS string that identifies the application.
     - parameter limit: The limit in bytes of the cache.  Defaults to 0
        which is no limit.
     */
    public init(path: String, logSubsystem: String, limit: UInt64 = 0) {
        self.path = path
        self.logSubsystem = logSubsystem
        self.manager = FileManager.default
        self.limit = limit
        guard let basePath = self.basePath else { return }
        logOnError("Create Base Path") {
            try self.manager.createDirectory(at: basePath,
                                             withIntermediateDirectories: true)
        }
        updateSize()
    }

    /**
     Get the value for an item in the cache.
     - parameter key: A `String` key used to lookup the object.
     - returns: A `Promise` for the resulting `Data` value if found.
     */
    public func get(key: String) -> Promise<Data> {
        return Promise(queue: queue, work: { fulfill, reject in
            guard let url = self.url(for: key) else {
                reject(CacheError.invalidURL)
                return
            }
            guard let data = try? Data(contentsOf: url, options: []) else {
                reject(CacheError.notFound)
                return
            }
            os_log("fetch for '%@'", log: self.logger, type: .info, key)
            self.updateModifiedDate(for: url.path).always {
                fulfill(data)
            }
        })
    }

    /**
     Set the value for an item in the cache.
     - parameter key: A `String` key used to lookup the object.
     - parameter value: A `Data` object to set for the given key.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func set(key: String, value: Data) -> Promise<Void> {
        return Promise(work: { fulfill, reject in
            self.queue.async(flags: .barrier) {
                guard let url = self.url(for: key) else {
                    reject(CacheError.invalidURL)
                    return
                }
                self.logOnError("Set File [\(key)]") {
                    try value.write(to: url, options: .atomicWrite)
                }

                // Update size and check if we need to evict items.
                self.size += UInt64(value.count)
                if self.limit > 0 && self.size > self.limit {
                    self.evictItems()
                }
                fulfill(())
            }
        })
    }

    /**
     Clear all items from the cache.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func clear() -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.queue.async(flags: .barrier) {
                self.getAll().forEach { url in
                    self.logOnError("Clear Item [\(url)]", action: {
                        try self.manager.removeItem(at: url)
                    })
                }
                self.updateSize()
                fulfill(())
            }
        })
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func remove(key: String) -> Promise<Void> {
        return Promise(work: { fulfill, reject in
            self.queue.async(flags: .barrier) {
                guard let url = self.url(for: key) else {
                    reject(CacheError.invalidURL)
                    return
                }

                guard self.manager.fileExists(atPath: url.path) else {
                    reject(CacheError.notFound)
                    return
                }

                self.logOnError("Remove item [\(key)]") {
                    let fileSize = self.getSize(for: url) ?? 0
                    try self.manager.removeItem(at: url)
                    self.reduceSize(by: fileSize)
                }
                fulfill(())
            }
        })
    }

    /**
     Evict items from the cache, if appropriate.  The cache does this
     as items are added, but this method forces a check for items that
     should be evicted.
     - returns: A Promise that fulfills when the operation is finished.
     */
    public func evict() -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.queue.async(flags: .barrier) {
                self.evictItems()
                fulfill(())
            }
        })
    }

    /**
     Get the current size of the disk cache by summing the size of all files
     in the cache.
     - returns: A Promise for the size of the cache.
     */
    public func getCacheSize() -> Promise<UInt64> {
        return Promise(work: { fulfill, _ in
            self.queue.async(flags: .barrier) {
                self.updateSize()
                fulfill(self.size)
            }
        })
    }

    /// Returns the filesystem path for a given key.
    private func path(for key: String) -> String? {
        guard let fileName = Crypto.sha256(string: key) else { return nil }
        let url = self.basePath?.appendingPathComponent(fileName)
        return url?.absoluteString
    }

    /// Returns the URL for a given key.
    private func url(for key: String) -> URL? {
        guard let path = path(for: key) else { return nil }
        return URL(string: path)
    }

    /// Update the modified date of the file at the given path.
    private func updateModifiedDate(for path: String) -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.queue.async(flags: .barrier) {
                let now = Date()
                self.logOnError("Set File Modification Data") {
                    try self.manager.setAttributes(
                        [FileAttributeKey.modificationDate: now],
                        ofItemAtPath: path)
                }
                fulfill(())
            }
        })
    }

    /// Returns the last modification date of the URL using the cached resources.
    private func getLastModified(for url: URL) -> Date {
        guard let resources = logOnError("getLastModified", action: {
            return try url.resourceValues(forKeys: [.contentModificationDateKey])
        }) else { return Date() }
        return resources.contentModificationDate ?? Date()
    }

    /// Returns the size of the URL using the cached resources.
    private func getSize(for url: URL) -> UInt64? {
        let resources = logOnError("getSize") {
            return try url.resourceValues(forKeys: [.fileSizeKey])
        }
        guard let size = resources?.fileSize else {
            return nil
        }
        return UInt64(size)
    }

    /**
     Return the contents of the cache directory with the file size
     sorted by last modified date.  The collection returned is lazy so
     the file sizes are only retrieved as needed.
     */
    private func contentsSortedByDate() -> [(URL, UInt64)] {
        let urls = getAll(with: [.contentModificationDateKey])
        return urls
            .sorted { (url1, url2) -> Bool in
                return getLastModified(for: url1) < getLastModified(for: url2)
            }
            .lazy
            .map { url -> (URL, UInt64) in
                return (url, getSize(for: url) ?? 0)
            }
    }

    /**
     Evict items so the cache size is not greater than the limit. A list
     of items are calculated that reduces the size below the limit and
     then those items are removed.
     */
    private func evictItems() {
        guard self.limit > 0 else { return }
        os_log("Cache limit exceeded: %d / %d",
               log: self.logger, type: .info,
               self.size, self.limit)

        let over = self.size - self.limit
        var total: UInt64 = 0

        let urlsToRemove = contentsSortedByDate()
            .prefix { (args) -> Bool in
                guard total < over else { return false }
                let (_, fileSize) = args
                total += fileSize
                return true
            }
        urlsToRemove.forEach { args in
            let (url, fileSize) = args
            os_log("Evicting %@ [%d]", log: self.logger, type: .info,
                   url.lastPathComponent, fileSize)
            self.logOnError("evictItems remove", action: {
                try self.manager.removeItem(at: url)
                self.reduceSize(by: fileSize)
            })
        }
    }

    /// Updates the cache size by summing the size of all files in the cache.
    private func updateSize() {
        let totalSize = getAll(with: [.fileSizeKey])
            .map { getSize(for: $0) ?? 0 }
            .reduce(0, +)
        self.size = totalSize
        os_log("updateSize: %d", log: self.logger, type: .info, totalSize)
    }

    /**
     Returns URLs for all items in the cache and pre-fetches URL resource
     values, if specified.
     */
    private func getAll(with properties: [URLResourceKey]? = nil) -> [URL] {
        guard let url = basePath,
            let fileUrls = logOnError("getAll", action: {
                try manager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: properties,
                    options: [.skipsHiddenFiles])
            }) else { return [] }
        return fileUrls
    }

    /// Reduce the cache size by the specified amount.
    private func reduceSize(by value: UInt64) {
        if value <= self.size {
            self.size -= value
        } else {
            self.size = 0
        }
    }
}

extension DiskCache {
    /**
     Removes items older than `olderThan` but excludes certain items from
     the cleanup.
     - parameter olderThan: The number of days since the last access.  Items
     older than this will be removed.
     - parameter excluding: A list of keys to be excluded from the cleanup.
     */
    public func cleanup(olderThan: UInt, excluding: [String]) -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.queue.async(flags: .barrier) {
                self._cleanup(olderThan: olderThan, excluding: excluding)
                self.updateSize()
                fulfill(())
            }
        })
    }

    // Internal function to perform the cleanup.
    private func _cleanup(olderThan: UInt, excluding: [String]) {
        let excludedItems = excluding.compactMap { key -> String? in
            guard let url = url(for: key) else { return nil }
            return url.lastPathComponent
        }
        let keys: Set<URLResourceKey> = [ .contentModificationDateKey ]
        let urls = getAll(with: Array(keys))
        let unused = urls.filter { url in
            return !excludedItems.contains(url.lastPathComponent)
        }

        os_log("Cleanup Total: %d, Unused: %d",
               log: logger, type: .info,
               urls.count, unused.count)

        unused.forEach { url in
            guard let resources = logOnError("Cleanup Value", action: {
                return try url.resourceValues(forKeys: keys)
            }) else { return }
            guard let lastModified = resources.contentModificationDate else { return }
            let daysOld = -1 * lastModified.timeIntervalSinceNow / DiskCache.HoursPerDay

            os_log("%@ - Days: %0.2f, Mod: %@",
                   log: logger, type: .info,
                   url.lastPathComponent, daysOld,
                   String(describing: lastModified))

            if daysOld > 0 && daysOld > Double(olderThan) {
                logOnError("Cleanup Remove", action: {
                    try self.manager.removeItem(at: url)
                    os_log("Deleted %@", log: logger,
                           type: .info, url.lastPathComponent)
                })
            }
        }
    }
}
