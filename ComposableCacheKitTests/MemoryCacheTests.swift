//
//  MemoryCacheTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

class MemoryCacheTests: XCTestCase {
    let key1 = "Key1"
    let key2 = "Key2"
    let value1 = "Value1"
    let value2 = "Value2"
    let cache = MemoryCache<NSString>(subsystem: "memorytest")
        .mappingValues(using: BidirectionalMappers.nsstringToString)

    override func setUp() {
    }

    override func tearDown() {
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

    func getShouldSucceed(key: String, value: String) {
        XCTWaitForPromise(cache.get(key: key)) { value, _ in
            XCTAssertEqual(value, value, "Value should be found!")
        }
    }

    func testCache() {
        getShouldFail(key: key1)
        getShouldFail(key: key2)

        XCTWaitForPromise(cache.set(key: key1, value: value1))
        XCTWaitForPromise(cache.set(key: key2, value: value2))

        getShouldSucceed(key: key1, value: value1)
        getShouldSucceed(key: key2, value: value2)

        XCTWaitForPromise(cache.remove(for: key2)) { _, _ in }
        getShouldFail(key: key2)
    }
}
