//
//  File.swift
//  
//
//  Created by Kevin on 7/10/21.
//

import XCTest

public enum XCAsyncError: Error {
    case timeout
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 15, *)
public extension XCTestCase {
    func asyncTest<T>(
        description: String = "Async Test",
        timeout: TimeInterval = 3,
        closure: @escaping () async throws -> T
    ) throws -> T {
        var result: Result<T, Error>?
        let expectation = self.expectation(description: description)
        let callback: (Result<T, Error>) -> Void = { returnedValue in
            DispatchQueue.main.async {
                result = returnedValue
                expectation.fulfill()
            }
        }
        Task.detached {
            do {
                let value = try await closure()
                callback(.success(value))
            } catch {
                callback(.failure(error))
            }
//            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: timeout)
        switch result {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        case nil:
            throw XCAsyncError.timeout
        }
    }
}
