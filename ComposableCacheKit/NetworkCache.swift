//
//  NetworkCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import os.log
import Promise

/// A read-only "cache" that just retrieves data from an URL.
public final class NetworkCache: ReadOnlyCache {
    private let subsystem: String
    private lazy var logger = {
        return OSLog(subsystem: subsystem, category: "networkcache")
    }()
    public typealias Key = String
    public typealias Value = Data

    /**
     Create a `NetworkCache`.
     - parameter subsystem: The subsystem name to use for logging.  Usually
     a reverse DNS string that identifies the application.
     */

    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    /**
     Get the value for an item in the cache.
     - parameter key: The `URL` key to retrieve.
     - returns: A `Promise` for the retrieved data.
     */
    public func get(key: String) -> Promise<Data> {
        os_log("fetch for '%@'", log: logger, type: .info, key)
        guard let url = URL(string: key) else {
            return Promise(error: CacheError.invalidURL)
        }
        return Promise(work: { fulfill, reject in
            let session = URLSession.shared
            session.dataTask(with: url, completionHandler: { data, _, error in
                if let error = error {
                    reject(error)
                } else if let data = data {
                    fulfill(data)
                }
            }).resume()
        })
    }
}
