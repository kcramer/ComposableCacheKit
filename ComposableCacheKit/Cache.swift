//
//  Cache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

/// A cache that can store values for keys.
public protocol Cache {
    associatedtype Key: Hashable
    associatedtype Value

    /**
     Get the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - returns: A `Promise` for the resulting data if it exists.
     */
    func get(key: Key) -> Promise<Value>

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    func set(key: Key, value: Value) -> Promise<Void>

    /**
     Clear all items from the cache.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    func clear() -> Promise<Void>

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    func remove(key: Key) -> Promise<Void>

    /**
     Evict items based on the eviction policy.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    func evict() -> Promise<Void>
}

// Provide no-op defaults for the less used functions.
extension Cache {
    public func remove(key: Key) -> Promise<Void> {
        return Promise(value: ())
    }

    public func evict() -> Promise<Void> {
        return Promise(value: ())
    }
}

/// A read-only cache.  Values can be retrieved but not set or cleared.
public protocol ReadOnlyCache: Cache { }

extension ReadOnlyCache {
    public func set(key: Key, value: Value) -> Promise<Void> {
        return Promise(value: ())
    }

    public func clear() -> Promise<Void> {
        return Promise(value: ())
    }
}
