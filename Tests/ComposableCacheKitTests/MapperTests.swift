//
//  MapperTests.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
@testable import ComposableCacheKit

class MapperTests: XCTestCase {
    func checkMapper<Mapper: BidirectionalMappable>(
        mapper: Mapper, value: Mapper.Output)
        where Mapper.Output: Equatable
    {
        do {
            let reversed = try mapper.reverse(from: value)
            let forward = try mapper.map(from: reversed)
            XCTAssertEqual(value,
                           forward,
                           "Values should be equal after mappings!")
        } catch {
            XCTFail("Mapping should return a value!")
        }
    }

    func testNSStringMapper() {
        checkMapper(mapper: BidirectionalMappers.nsstringToString,
                    value: "String to Test")
    }

    func testStringMapper() {
        checkMapper(mapper: BidirectionalMappers.dataToStringMapper,
                    value: "String to Test")
    }
}
