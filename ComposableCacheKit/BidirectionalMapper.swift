//
//  BidirectionalMapper.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import Promise

/// An object that converts from one type to another and vice versa.
public protocol BidirectionalMappable {
    associatedtype Input
    associatedtype Output

    /// Given an input, return a Promise for the output.
    func map(from: Input) -> Promise<Output>
    /// Given an input, return a Promise for the output.
    func reverse(from: Output) -> Promise<Input>
}

/// An object that converts from the `Input` to the `Output` type and vice versa.
public struct BidirectionalMapper<I, O>: BidirectionalMappable {
    public typealias Input = I
    public typealias Output = O

    private let forward: (Input) -> Promise<Output>
    private let reverse: (Output) -> Promise<Input>

    /// Create a mapper given the forward and reverse functions.
    public init(forward: @escaping (Input) -> Promise<Output>,
                reverse: @escaping (Output) -> Promise<Input>) {
        self.forward = forward
        self.reverse = reverse
    }

    /// Returns a Promise for an `Output` given an `Input`.
    /// - parameter from: The type of `Input` to be mapped to the `Output` type.
    /// - returns: The `Input` mapped to the `Output` type.
    public func map(from: Input) -> Promise<Output> {
        return forward(from)
    }

    /// Returns a Promise for an `Input` given an `Output`.
    /// - parameter from: A type of `Output` to be mapped to the `Input` type.
    /// - returns: The `Output` mapped to the `Input` type.
    public func reverse(from: Output) -> Promise<Input> {
        return reverse(from)
    }

    /// Returns a mapper that works in the reverse direction.
    /// - returns: A mapper that works in the reverse direction.
    public func reverseMapping() -> BidirectionalMapper<Output, Input> {
        return BidirectionalMapper<Output, Input>(
            forward: self.reverse, reverse: self.forward)
    }
}
