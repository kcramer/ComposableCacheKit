//
//  CacheError.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/7/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation

/// An error thrown by a cache or related object.
public enum CacheError: Error, Equatable {
    /// Requested item not found.
    case notFound
    /// Error converting a data type to another data type.
    case conversionError
    /// The URL was invalid and could not be used.
    case invalidURL
    /// Error retrieving the data.
    case retrievalError(CocoaError)
    /// A general error with text description.
    case generalError(String)
}
