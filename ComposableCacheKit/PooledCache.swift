//
//  PooledCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/2/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

/**
 A cache that acts as a proxy for another cache and pools inflight requests
 for the same key and returns the same `Promise` for all such requests.  All
 other operations are passed to the underlying cache.
 */
public final class PooledCache<C>: Cache where C: Cache {
    public typealias Key = C.Key
    public typealias Value = C.Value
    private let cache: C
    private let queue = DispatchQueue(
        label: FrameworkConstants.identifier + ".pooledcache",
        qos: .userInitiated)
    private var requests: [Key: Promise<Value>] = [:]

    /**
     Create a `PooledCache`.
     - parameter from: The backing cache for which requests are pooled.
     */
    public init(from cache: C) {
        self.cache = cache
    }

    /**
     Get the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - returns: A `Promise` for the resulting value if found.
     */
    public func get(key: Key) -> Promise<Value> {
        // Lookup / create the request on the serial queue.
        return queue.sync {
            // If there is an existing request for the key, return it.
            if let existing = requests[key] {
                return existing
            }
            // Otherwise create a request and add it to the collection.
            let request = cache.get(key: key)
            requests[key] = request
            // Remove the request on the serial queue.
            request.always(on: queue) { [weak self] in
                guard let self = self else { return }
                self.requests.removeValue(forKey: key)
            }
            return request
        }
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func set(key: Key, value: Value) -> Promise<Void> {
        return cache.set(key: key, value: value)
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func remove(key: C.Key) -> Promise<Void> {
        return cache.remove(key: key)
    }

    /**
     Clear all items from the cache.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func clear() -> Promise<Void> {
        return cache.clear()
    }

    /**
     Evict items based on the eviction policy.
     - returns: A `Promise` that fulfills when the operation is finished.
     */
    public func evict() -> Promise<Void> {
        return cache.evict()
    }
}

extension Cache {
    /// Returns a new cache based on this cache that pools requests.
    public func pooled() -> PooledCache<Self> {
        return PooledCache(from: self)
    }
}
