//
//  MemoryCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 2/17/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import os.log

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
     - returns: The value for the specified key if found.
     */
    public func get(key: Key) async throws -> Value {
        guard let item = self.cache.object(forKey: key as NSString) else {
            throw CacheError.notFound
        }
        os_log("cache hit for '%@'", log: self.logger, type: .debug, key)
        return item
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The `String` key used to lookup the object.
     - parameter value: The value to store for the given key.
     */
    public func set(key: Key, value: Value) async throws {
        self.cache.setObject(value, forKey: key as NSString)
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     */
    public func remove(key: Key) async throws {
        self.cache.removeObject(forKey: key as NSString)
    }

    /// Clear the cache by removing all items.
    private func clearMemoryCache() {
        cache.removeAllObjects()
    }

    /**
     Clear all items from the cache.
     */
    public func clear() async throws {
        self.clearMemoryCache()
    }
}
