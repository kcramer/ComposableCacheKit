//
//  DiskCacheTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
class DiskCacheTests: XCTestCase {
    let cache = DiskCache(path: TestingConstants.diskCachePath,
                          logSubsystem: "diskcache")
    let key1 = "Key1"
    let value1 = "Value1"
    let key2 = "Key2"
    let value2 = "Value2"

    override func setUp() {
        try? self.asyncTest(description: "Clear Cache", timeout: 5) {
            return try await self.cache.clear()
        }
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

    func testNotFound() {
        let key = "NonExistentKey"
        getShouldFail(key: key)
    }

    func testSettingAndRemovingValues() {
        // Set and test first value.
        getShouldFail(key: key1)
        let data1 = value1.data(using: .utf8) ?? Data()

        try? self.asyncTest(description: "Set cache key") {
            try await self.cache.set(key: self.key1, value: data1)
        }
        getShouldSucceed(key: key1, value: data1)

        // Set and test second value.
        getShouldFail(key: key2)
        let data2 = value2.data(using: .utf8) ?? Data()
        try? self.asyncTest(description: "Set cache key") {
            try await self.cache.set(key: self.key2, value: data2)
        }
        getShouldSucceed(key: key2, value: data2)

        // Remove the second value.
        try? self.asyncTest(description: "Remove cache key") {
            try await self.cache.remove(key: self.key2)
        }
        getShouldFail(key: key2)

        // Remove the first value.
        try? self.asyncTest(description: "Remove cache key") {
            try await self.cache.remove(key: self.key1)
        }
        getShouldFail(key: key1)
    }
}
