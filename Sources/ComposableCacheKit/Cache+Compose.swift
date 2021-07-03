//
//  Cache+Compose.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

extension Cache {
    /**
     Compose this cache with another cache.  Lookups are processed by this
     cache and if not successful are handled by the other, secondary cache.
     Modifications are processed by both caches.
     - parameter with: The secondary cache to use.
     - returns: A composite cache that uses this cache, then the secondary cache.
     */
    public func compose<C: Cache>(with cache: C) -> SimpleCache<C.Key, C.Value>
        where C.Key == Key, C.Value == Value {
            return SimpleCache(
                // TODO: Catch notFound specifically or keep as all errors?
                get: { key -> Value in
                    do {
                        let value = try await self.get(key: key)
                        return value
                    } catch {
                        do {
                            let value = try await cache.get(key: key)
                            try await self.set(key: key, value: value)
                            return value
                        } catch {
                            throw error
                        }
                    }
                },
                set: { (key, value) in
                    try await self.set(key: key, value: value)
                    try await cache.set(key: key, value: value)
                },
                clear: {
                    try await self.clear()
                    try await cache.clear()
                },
                remove: { key in
                    try await self.remove(key: key)
                    try await cache.remove(key: key)
                },
                evict: {
                    try await self.evict()
                    try await cache.evict()
                })
    }
}
