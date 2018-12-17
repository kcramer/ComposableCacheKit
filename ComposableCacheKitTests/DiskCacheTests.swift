//
//  DiskCacheTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

class DiskCacheTests: XCTestCase {
    let cache = DiskCache(path: TestingConstants.diskCachePath,
                          logSubsystem: "diskcache")
    let key1 = "Key1"
    let value1 = "Value1"
    let key2 = "Key2"
    let value2 = "Value2"

    override func setUp() {
        XCTWaitForPromise(cache.clear())
    }

    func getShouldFail(key: String) {
        XCTWaitForPromise(cache.get(key: key)) { _, error in
            guard let error = error, let cacheError = error as? CacheError else {
                XCTFail("Should not have a value or unknown error")
                return
            }
            XCTAssertEqual(cacheError, CacheError.notFound, "Key should not be found!")
        }
    }

    func getShouldSucceed(key: String, value: Data) {
        XCTWaitForPromise(cache.get(key: key)) { data, _ in
            XCTAssertEqual(value, data, "Value should be found!")
        }
    }

    func getShouldSucceed(key: String, string: String) {
        let data = string.data(using: .utf8)
        getShouldSucceed(key: key, value: data!)
    }

    func testNotFound() {
        let key = "NonExistentKey"
        getShouldFail(key: key)
    }

    func testSettingAndRemovingValues() {
        // Set and test first value.
        getShouldFail(key: key1)
        let data1 = value1.data(using: .utf8) ?? Data()
        XCTWaitForPromise(cache.set(key: key1, value: data1))
        getShouldSucceed(key: key1, value: data1)

        // Set and test second value.
        getShouldFail(key: key2)
        let data2 = value2.data(using: .utf8) ?? Data()
        XCTWaitForPromise(cache.set(key: key2, value: data2))
        getShouldSucceed(key: key2, value: data2)

        // Remove the second value.
        XCTWaitForPromise(cache.remove(key: key2))
        getShouldFail(key: key2)

        // Remove the first value.
        XCTWaitForPromise(cache.remove(key: key1))
        getShouldFail(key: key1)
    }
}
