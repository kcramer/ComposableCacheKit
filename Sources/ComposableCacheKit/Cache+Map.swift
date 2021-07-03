//
//  Cache+Map.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

extension Cache {
    /**
     Converts the values of the cache from one type to another using
     the provided BidirectionalMappable.
     - parameter using: The mapper to use for the mapping.
     - returns: A cache that wraps the original cache acting as a proxy that
        performs the mapping then passes requests to the original cache.
     */
    public func mappingValues<T: BidirectionalMappable>(using mapper: T)
        -> SimpleCache<Key, T.Output> where Value == T.Input {
        return SimpleCache(
            get: { key -> T.Output in
                let value = try await self.get(key: key)
                return try mapper.map(from: value)
            },
            set: { (key, value) in
                let mappedValue = try mapper.reverse(from: value)
                return try await self.set(key: key, value: mappedValue)
            },
            clear: {
                return try await self.clear()
            },
            remove: { key in
                return try await self.remove(key: key)
            },
            evict: {
                return try await self.evict()
            })
    }

    /**
     Converts the keys of the cache from one type to another using
     the provided BidirectionalMappable.
     - parameter using: The mapper to use for the mapping.
     - returns: A cache that wraps the original cache acting as a proxy that
        performs the mapping then passes requests to the original cache.
     */
    public func mappingKeys<T: BidirectionalMappable>(using mapper: T)
        -> SimpleCache<T.Output, Value> where Key == T.Input {
        return SimpleCache(
            get: { key -> Value in
                let mappedKey = try mapper.reverse(from: key)
                return try await self.get(key: mappedKey)
            },
            set: { (key, value) in
                let mappedKey = try mapper.reverse(from: key)
                return try await self.set(key: mappedKey, value: value)
            },
            clear: {
                return try await self.clear()
            },
            remove: { key in
                let mappedKey = try mapper.reverse(from: key)
                return try await self.remove(key: mappedKey)
            },
            evict: {
                return try await self.evict()
            })
    }
}
