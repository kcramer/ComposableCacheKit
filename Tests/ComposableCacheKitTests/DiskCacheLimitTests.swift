//
//  DiskCacheLimitTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/11/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 15, *)
class DiskCacheLimitTests: XCTestCase {
    let cache = DiskCache(path: TestingConstants.diskCachePath,
                          logSubsystem: "diskcache",
                          limit: 5000)
    let mediumData = [
        "m1": Data(count: 1000),
        "m2": Data(count: 1000),
        "m3": Data(count: 1000),
        "m4": Data(count: 1000),
        "m5": Data(count: 1000),
        "m6": Data(count: 1000)
    ]
    let largeData = [
        "l1": Data(count: 2000),
        "l2": Data(count: 2000),
        "l3": Data(count: 2000)
    ]

    func assertCacheSize(expected: UInt64) {
        let size = cache.getCacheSize()
        guard size == expected else {
            XCTFail("Cache size should be \(expected)!")
            return
        }
    }

    override func setUp() {
        try? self.asyncTest(description: "Clear Cache", timeout: 5) {
            return try await self.cache.clear()
        }
        assertCacheSize(expected: 0)
    }

    func getShouldFail(key: String) {
        do {
            let _ = try self.asyncTest(description: "Get should fail") {
                return try await self.cache.get(key: key)
            }
            XCTFail("Should have no value!")
        } catch is CacheError {
            return
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }

    func getShouldSucceed(key: String, value: Data) {
        do {
            let data = try self.asyncTest(description: "Get Should Succeed") {
                return try await self.cache.get(key: key)
            }
            XCTAssertEqual(value, data, "Incorrect value found for key [\(key)]!")
        } catch {
            XCTFail("Value should be found for key [\(key)]!")
        }
    }

    func getShouldSucceed(key: String, string: String) {
        let data = string.data(using: .utf8)
        getShouldSucceed(key: key, value: data!)
    }

    /// Test that adding an item that causes the cache to exceed
    /// the limit and results in an eviction of the oldest item.
    func testEvictionExceeds() {
        // Insert each key/value into the cache in order.
        let keys = largeData.keys.sorted()
        keys.forEach { key in
            guard let data = largeData[key] else {
                XCTFail("Data for key '\(key)' should not be nil!")
                return
            }
            try? self.asyncTest(description: "Set cache key", timeout: 4) {
                try await Task.sleep(nanoseconds: UInt64(1.1 * 1_000_000_000))
                try await self.cache.set(key: key, value: data)
            }
        }

        // The first key added should be evicted due to exceeding the limit.
        guard let firstKey = keys.first else {
            XCTFail("First key should not be nil!")
            return
        }
        getShouldFail(key: firstKey)
        // The remaining keys should still be found.
        let remainingKeys = keys.dropFirst()
        remainingKeys.forEach { key in
            guard let data = largeData[key] else {
                XCTFail("Data for key '\(key)' should not be nil!")
                return
            }
            getShouldSucceed(key: key, value: data)
        }
        assertCacheSize(expected: 4000)
    }

    /// Test that the limit can be reached without eviction but the next
    /// item added will force an eviction of the oldest item.
    func testEvictionEquals() {
        // Insert each key/value into the cache in order.
        let keys = mediumData.keys.sorted()
        keys.forEach { key in
            guard let data = mediumData[key] else {
                XCTFail("Data for key '\(key)' should not be nil!")
                return
            }
            // Add a delay to ensure the Travis build works.
            try? self.asyncTest(description: "Set cache key", timeout: 4) {
                try await Task.sleep(nanoseconds: UInt64(1.1 * 1_000_000_000))
                try await self.cache.set(key: key, value: data)
            }
        }

        // The first key added should be evicted due to exceeding the limit.
        guard let firstKey = keys.first else {
            XCTFail("First key should not be nil!")
            return
        }
        getShouldFail(key: firstKey)
        // The remaining keys should still be found.
        let remainingKeys = keys.dropFirst()
        remainingKeys.forEach { key in
            guard let data = mediumData[key] else {
                XCTFail("Data for key '\(key)' should not be nil!")
                return
            }
            getShouldSucceed(key: key, value: data)
        }
        assertCacheSize(expected: 5000)
    }
}
