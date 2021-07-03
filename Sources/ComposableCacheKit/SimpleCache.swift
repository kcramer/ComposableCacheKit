//
//  SimpleCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

/// A simple cache that uses the provided functions as its implementation.
public final class SimpleCache<K, V>: Cache where K: Hashable {
    public typealias Key = K
    public typealias Value = V
    private let getFunc: (Key) async throws -> Value
    private let setFunc: (Key, Value) async throws -> Void
    private let removeFunc: (Key) async throws -> Void
    private let clearFunc: () async throws -> Void
    private let evictFunc: () async throws -> Void

    /**
     Create a `SimpleCache`.
     - parameter get: The function used to get an item.
     - parameter set: The function used to get an item.
     - parameter clear: The function used to clear the cache.
     - parameter remove: The function used to remove an item.
     - parameter evict: The function used to evict items.
     */
    public init(get: @escaping (Key) async throws -> Value,
                set: @escaping (Key, Value) async throws -> Void,
                clear: @escaping () async throws -> Void,
                remove: @escaping (Key) async throws -> Void,
                evict: @escaping () async throws -> Void) {
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
            return try await cache.get(key: key)
        }
        self.setFunc = { key, value in
            return try await cache.set(key: key, value: value)
        }
        self.removeFunc = { key in
            return try await cache.remove(key: key)
        }
        self.clearFunc = {
            return try await cache.clear()
        }
        self.evictFunc = {
            return try await cache.evict()
        }
    }

    /**
     Get the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - returns: The value for the specified key if found.
     */
    public func get(key: Key) async throws -> Value {
        return try await getFunc(key)
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     */
    public func set(key: Key, value: Value) async throws {
        return try await setFunc(key, value)
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     */
    public func remove(key: K) async throws {
        return try await removeFunc(key)
    }

    /**
     Clear all items from the cache.
     */
    public func clear() async throws {
        return try await clearFunc()
    }

    /**
     Evict items based on the eviction policy.
     */
    public func evict() async throws {
        return try await evictFunc()
    }
}
