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
        where Mapper.Output: Equatable {
        let mapping = mapper.reverse(from: value).then { converted in
            return mapper.map(from: converted)
        }
        XCTWaitForPromise(mapping) { (converted, _) in
            guard let converted = converted else {
                XCTFail("Mapping should return a value!")
                return
            }
            XCTAssertEqual(value,
                           converted,
                           "Values should be equal after mappings!")
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
