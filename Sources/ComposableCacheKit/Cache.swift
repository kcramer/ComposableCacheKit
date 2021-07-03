//
//  Cache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

/// A cache that can store values for keys.
public protocol Cache {
    associatedtype Key: Hashable
    associatedtype Value

    /**
     Get the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - returns: The value for the specified key if it exists.
     */
    func get(key: Key) async throws -> Value

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     */
    func set(key: Key, value: Value) async throws

    /**
     Clear all items from the cache.
     */
    func clear() async throws

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     */
    func remove(key: Key) async throws

    /**
     Evict items based on the eviction policy.
     */
    func evict() async throws
}

// Provide no-op defaults for the less used functions.
extension Cache {
    public func remove(key: Key) async throws {
        return
    }

    public func evict() async {
        return
    }
}

/// A read-only cache.  Values can be retrieved but not set or cleared.
public protocol ReadOnlyCache: Cache { }

extension ReadOnlyCache {
    public func set(key: Key, value: Value) async throws {
        return
    }

    public func clear() async throws {
        return
    }
}
