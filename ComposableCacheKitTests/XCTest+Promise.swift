//
//  XCTest+Promise.swift
//  ComposableCacheKitTests
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import XCTest
import Promise

extension XCTestCase {
    func XCTWaitForPromise<Value>(
        _ promise: Promise<Value>,
        timeout: TimeInterval = 5,
        completion: @escaping (Value?, Error?) -> Void = { _, _ in }) {

        let expectation = XCTestExpectation(description: "promise expectation")
        promise
            .then({ value in
                completion(value, nil)
                expectation.fulfill()
            })
            .catch({ error in
                completion(nil, error)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: timeout)
    }
}
