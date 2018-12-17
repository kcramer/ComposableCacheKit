//
//  MemoryCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 2/17/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import os.log
import Promise

/// A memory-based cache that uses NSCache.
public class MemoryCache<V>: Cache where V: AnyObject {
    public typealias Key = String
    public typealias Value = V
    private let subsystem: String
    private lazy var logger = {
        return OSLog(subsystem: subsystem, category: "memorycache")
    }()
    private let cache = NSCache<NSString, Value>()

    /**
     Create a `MemoryCache`.
     - parameter subsystem: The subsystem name to use for logging.  Usually
     a reverse DNS string that identifies the application.
     */
    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    /**
     Get the value for an item in the cache.
     - parameter key: A `String` key used to lookup the object.
     - returns: A `Promise` for the resulting value if found.
     */
    public func get(key: Key) -> Promise<Value> {
        return Promise(work: { fulfill, reject in
            guard let item = self.cache.object(forKey: key as NSString) else {
                reject(CacheError.notFound)
                return
            }
            os_log("cache hit for '%@'", log: self.logger, type: .debug, key)
            fulfill(item)
        })
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The `String` key used to lookup the object.
     - parameter value: The value to store for the given key.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func set(key: Key, value: Value) -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.cache.setObject(value, forKey: key as NSString)
            fulfill(())
        })
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func remove(key: String) -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.cache.removeObject(forKey: key as NSString)
            fulfill(())
        })
    }

    /// Clear the cache by removing all items.
    private func clearMemoryCache() {
        cache.removeAllObjects()
    }

    /**
     Clear all items from the cache.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func clear() -> Promise<Void> {
        return Promise(work: { fulfill, _ in
            self.clearMemoryCache()
            fulfill(())
        })
    }
}
