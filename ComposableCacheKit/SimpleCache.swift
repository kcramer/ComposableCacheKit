//
//  SimpleCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

/// A simple cache that uses the provided functions as its implementation.
public final class SimpleCache<K, V>: Cache where K: Hashable {
    public typealias Key = K
    public typealias Value = V
    private let getFunc: (Key) -> Promise<Value>
    private let setFunc: (Key, Value) -> Promise<Void>
    private let removeFunc: (Key) -> Promise<Void>
    private let clearFunc: () -> Promise<Void>
    private let evictFunc: () -> Promise<Void>

    /**
     Create a `SimpleCache`.
     - parameter get: The function used to get an item.
     - parameter set: The function used to get an item.
     - parameter clear: The function used to clear the cache.
     - parameter remove: The function used to remove an item.
     - parameter evict: The function used to evict items.
     */
    public init(get: @escaping (Key) -> Promise<Value>,
                set: @escaping (Key, Value) -> Promise<Void>,
                clear: @escaping () -> Promise<Void>,
                remove: @escaping (Key) -> Promise<Void>,
                evict: @escaping () -> Promise<Void>) {
        self.getFunc = get
        self.setFunc = set
        self.clearFunc = clear
        self.removeFunc = remove
        self.evictFunc = evict
    }

    /**
     Create a `SimpleCache` from another cache.
     - parameter from: The backing cache for this cache.  All requests are
        passed to the backing cache.
     */
    public init<C: Cache>(from cache: C) where K == C.Key, V == C.Value {
        self.getFunc = { key in
            return cache.get(key: key)
        }
        self.setFunc = { key, value in
            return cache.set(key: key, value: value)
        }
        self.removeFunc = { key in
            return cache.remove(key: key)
        }
        self.clearFunc = {
            return cache.clear()
        }
        self.evictFunc = {
            return cache.evict()
        }
    }

    /**
     Get the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - returns: A `Promise` for the resulting data if found.
     */
    public func get(key: Key) -> Promise<Value> {
        return getFunc(key)
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func set(key: Key, value: Value) -> Promise<Void> {
        return setFunc(key, value)
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func remove(for key: K) -> Promise<Void> {
        return removeFunc(key)
    }

    /**
     Clear all items from the cache.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func clear() -> Promise<Void> {
        return clearFunc()
    }

    /**
     Evict items based on the eviction policy.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func evict() -> Promise<Void> {
        return evictFunc()
    }
}
