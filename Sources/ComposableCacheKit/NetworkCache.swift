//
//  NetworkCache.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/1/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import os.log

/// A read-only "cache" that just retrieves data from an URL.
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 15, *)
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
     - returns: The value for the specified key if found.
     */
    public func get(key: String) async throws -> Data {
        os_log("fetch for '%@'", log: logger, type: .info, key)
        guard let url = URL(string: key) else {
            throw CacheError.invalidURL
        }
        let session = URLSession.shared
        let request = URLRequest(url: url)
        // Call the appropriate version based on OS version.
        if #available(macOS 12, iOS 15, watchOS 8, tvOS 15, macCatalyst 15, *) {
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            guard statusCode == 200 else {
                throw CacheError.invalidStatus(statusCode)
            }
            return data
        } else {
            let (data, response) = try await session.data(from: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            guard statusCode == 200 else {
                throw CacheError.invalidStatus(statusCode)
            }
            return data
        }
    }
}

@available(iOS, deprecated: 15, message: "Use the built-in API instead")
@available(macOS, deprecated: 12, message: "Use the built-in API instead")
@available(watchOS, deprecated: 8, message: "Use the built-in API instead")
@available(tvOS, deprecated: 15, message: "Use the built-in API instead")
@available(macCatalyst, deprecated: 16, message: "Use the built-in API instead")
extension URLSession {
    func data(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
