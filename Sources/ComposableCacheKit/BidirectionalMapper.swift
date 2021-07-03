//
//  BidirectionalMapper.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

/// An object that converts from one type to another and vice versa.
public protocol BidirectionalMappable {
    associatedtype Input
    associatedtype Output

    /// Given an input, return the output.
    func map(from: Input) throws -> Output
    /// Given an output, reverse and return the input.
    func reverse(from: Output) throws -> Input
}

/// An object that converts from the `Input` to the `Output` type and vice versa.
public struct BidirectionalMapper<I, O>: BidirectionalMappable {
    public typealias Input = I
    public typealias Output = O

    private let forward: (Input) throws -> Output
    private let reverse: (Output) throws -> Input

    /// Create a mapper given the forward and reverse functions.
    public init(forward: @escaping (Input) throws -> Output,
                reverse: @escaping (Output) throws -> Input) {
        self.forward = forward
        self.reverse = reverse
    }

    /// Returns an `Output` given an `Input`.
    /// - parameter from: The type of `Input` to be mapped to the `Output` type.
    /// - returns: The `Input` mapped to the `Output` type.
    public func map(from: Input) throws -> Output {
        return try forward(from)
    }

    /// Returns an `Input` given an `Output`.
    /// - parameter from: A type of `Output` to be mapped to the `Input` type.
    /// - returns: The `Output` mapped to the `Input` type.
    public func reverse(from: Output) throws -> Input {
        return try reverse(from)
    }

    /// Returns a mapper that works in the reverse direction.
    /// - returns: A mapper that works in the reverse direction.
    public func reverseMapping() -> BidirectionalMapper<Output, Input> {
        return BidirectionalMapper<Output, Input>(
            forward: self.reverse, reverse: self.forward)
    }
}
