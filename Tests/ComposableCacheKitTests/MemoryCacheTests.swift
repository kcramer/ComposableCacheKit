//
//  MemoryCacheTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
class MemoryCacheTests: XCTestCase {
    let key1 = "Key1"
    let key2 = "Key2"
    let value1 = "Value1"
    let value2 = "Value2"
    let cache = MemoryCache<NSString>(subsystem: "memorytest")
        .mappingValues(using: BidirectionalMappers.nsstringToString)

    override func setUp() {
        try? self.asyncTest(description: "Clear Cache", timeout: 5) {
            return try await self.cache.clear()
        }
    }

    override func tearDown() {
    }

    func getShouldFail(key: String) {
        do {
            let value = try self.asyncTest(description: "Get should fail") {
                return try await self.cache.get(key: key)
            }
            XCTFail("Should have no value! [returned '\(value)']")
        } catch is CacheError {
            return
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }

    func getShouldSucceed(key: String, value: String) {
        do {
            let data = try self.asyncTest(description: "Get Should Succeed") {
                return try await self.cache.get(key: key)
            }
            XCTAssertEqual(value, data, "Incorrect value found for key [\(key)]!")
        } catch {
            XCTFail("Value should be found for key [\(key)]!")
        }
    }

    func testCache() {
        getShouldFail(key: key1)
        getShouldFail(key: key2)

        try? self.asyncTest(description: "Set cache key") {
            try await self.cache.set(key: self.key1, value: self.value1)
        }
        try? self.asyncTest(description: "Set cache key") {
            try await self.cache.set(key: self.key2, value: self.value2)
        }

        getShouldSucceed(key: key1, value: value1)
        getShouldSucceed(key: key2, value: value2)

        try? self.asyncTest(description: "Remove cache key") {
            try await self.cache.remove(key: self.key2)
        }
        getShouldFail(key: key2)
    }
}
