//
//  DiskCacheLimitTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/11/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
import Promise
@testable import ComposableCacheKit

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
        XCTWaitForPromise(cache.getCacheSize(), timeout: 10) { value, _ in
            guard let size = value, size == expected else {
                XCTFail("Cache size should be \(expected)!")
                return
            }
        }
    }

    override func setUp() {
        XCTWaitForPromise(cache.clear())
        assertCacheSize(expected: 0)
    }

    func getShouldFail(key: String) {
        XCTWaitForPromise(cache.get(key: key)) { _, error in
            guard let cacheError = error as? CacheError else {
                XCTFail("Should have no value or unknown error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(cacheError, CacheError.notFound, "Key should not be found!")
        }
    }

    func getShouldSucceed(key: String, value: Data) {
        XCTWaitForPromise(cache.get(key: key)) { data, _ in
            XCTAssertEqual(value, data, "Value should be found for key [\(key)]!")
        }
    }

    func getShouldSucceed(key: String, string: String) {
        let data = string.data(using: .utf8)
        getShouldSucceed(key: key, value: data!)
    }

    /// Test that adding an item that causes the cache to exceed
    /// the limit results in an eviction of the oldest item.
    func testEvictionExceeds() {
        // Insert each key/value into the cache in order.
        let keys = largeData.keys.sorted()
        keys.forEach { key in
            guard let data = largeData[key] else {
                XCTFail("Data for key '\(key)' should not be nil!")
                return
            }
            XCTWaitForPromise(Promises.delay(1.1))
            XCTWaitForPromise(cache.set(key: key, value: data))
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
            XCTWaitForPromise(Promises.delay(1.1))
            XCTWaitForPromise(cache.set(key: key, value: data))
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
