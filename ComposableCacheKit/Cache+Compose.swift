//
//  Cache+Compose.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

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
                get: { key -> Promise<Value> in
                    return Promise(work: { fulfill, reject in
                        self.get(key: key)
                            .then({ value in
                                fulfill(value)
                            })
                            .catch({ error in
                                cache.get(key: key)
                                    .then({ value in
                                        _ = self.set(key: key, value: value)
                                        fulfill(value)
                                    })
                                    .catch({ error in
                                        reject(error)
                                    })
                            })
                    })
                },
                set: { (key, value) -> Promise<Void> in
                    let primary = self.set(key: key, value: value)
                    let secondary = cache.set(key: key, value: value)
                    return Promises
                        .all([primary, secondary])
                        .then({ _ in return () })
                },
                clear: {
                    return Promises
                        .all([self.clear(), cache.clear()])
                        .then({ _ in return () })
                },
                remove: { key -> Promise<Void> in
                    return Promises
                        .all([self.remove(key: key), cache.remove(key: key)])
                        .then({ _ in return () })
                },
                evict: {
                    return Promises
                        .all([self.evict(), cache.evict()])
                        .then({ _ in return () })
                })
    }
}
