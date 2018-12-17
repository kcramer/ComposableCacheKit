//
//  Cache+Map.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

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
            get: { key -> Promise<T.Output> in
                return self.get(key: key).then({ value in
                    return mapper.map(from: value)
                })
            },
            set: { (key, value) -> Promise<Void> in
                return mapper.reverse(from: value).then({ newValue in
                    return self.set(key: key, value: newValue)
                })
            },
            clear: {
                return self.clear()
            },
            remove: { key -> Promise<Void> in
                return self.remove(key: key)
            },
            evict: {
                return self.evict()
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
            get: { key -> Promise<Value> in
                return mapper.reverse(from: key).then({ newKey in
                    return self.get(key: newKey)
                })
            },
            set: { (key, value) -> Promise<Void> in
                return mapper.reverse(from: key).then({ newKey in
                    return self.set(key: newKey, value: value)
                })
            },
            clear: {
                return self.clear()
            },
            remove: { key -> Promise<Void> in
                return mapper.reverse(from: key).then({ newKey in
                    return self.remove(key: newKey)
                })
            },
            evict: {
                return self.evict()
            })
    }
}
