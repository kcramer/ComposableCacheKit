//
//  PooledCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/2/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

/**
 A cache that acts as a proxy for another cache and pools inflight requests
 for the same key.  All other operations are passed to the underlying cache.
 */
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 15, *)
public final class PooledCache<C>: Cache where C: Cache {
    public typealias Key = C.Key
    public typealias Value = C.Value
    private let cache: C

    /** TODO: Should the values be removed from this cache at some point?
            It could be duplicating caching of the underlying cache.
     **/
    actor RequestCache {
        private enum CacheEntry {
            case inProgress(Task<Value, Error>)
            case ready(Value)
        }
        private var cache: [Key: CacheEntry] = [:]

        func get(from key: Key,
                 getter: @escaping (Key) async throws -> Value) async throws -> Value? {
            if let cached = cache[key] {
                switch cached {
                case .inProgress(let handle):
                    return try await handle.value
                case .ready(let value):
                    return value
                }
            }

            let handle = Task.detached(priority: .userInitiated) {
                return try await getter(key)
            }

            cache[key] = .inProgress(handle)

            do {
                let value = try await handle.value
                cache[key] = .ready(value)
                return value
            } catch {
                cache[key] = nil
                throw error
            }
        }
    }
    private var requestCache = RequestCache()

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
     - returns: The value returned from the underlying cache if found.
     */
    public func get(key: Key) async throws -> Value {
        // Use the actor to find the key/value.
        let value = try await requestCache.get(from: key) { [weak self] key in
            guard let self = self else {
                throw CacheError.generalError("self not found")
            }
            return try await self.cache.get(key: key)
        }
        guard let value = value else {
            throw CacheError.notFound
        }
        try await cache.set(key: key, value: value)
        return value
    }

    /**
     Set the value for an item in the cache.
     - parameter key: The key used to lookup the object.
     - parameter value: The value to store for the given key.
     */
    public func set(key: Key, value: Value) async throws {
        return try await cache.set(key: key, value: value)
    }

    /**
     Removes the item specified by the key from the cache.
     - parameter key: The key to remove.
     */
    public func remove(key: C.Key) async throws {
        return try await cache.remove(key: key)
    }

    /**
     Clear all items from the cache.
     */
    public func clear() async throws {
        return try await cache.clear()
    }

    /**
     Evict items based on the eviction policy.
     */
    public func evict() async throws {
        return try await cache.evict()
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 15, *)
extension Cache {
    /// Returns a new cache based on this cache that pools requests.
    public func pooled() -> PooledCache<Self> {
        return PooledCache(from: self)
    }
}
