//
//  Mappers.swift
//  ComposableCacheKit
//
//  Created by Kevin on 11/30/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
    typealias Image = UIImage
#elseif os(OSX)
    import AppKit
    typealias Image = NSImage
#endif

/// Group of commonly used mappers.
public enum BidirectionalMappers {
    /// Map from a Data to a String.
    public static let dataToStringMapper = BidirectionalMapper<Data, String>(
        forward: { data in
            guard let string = String(data: data, encoding: .utf8) else {
                throw CacheError.conversionError
            }
            return string
        },
        reverse: { string in
            guard let data = string.data(using: .utf8) else {
                throw CacheError.conversionError
            }
            return data
        })

    /// Map from a NSString to String.
    public static let nsstringToString = BidirectionalMapper<NSString, String>(
        forward: { nsstring in
            return nsstring as String
        },
        reverse: { string in
            return string as NSString
        })
}

extension BidirectionalMappers {
    #if os(iOS) || os(tvOS) || os(watchOS)
    /// Map from a Data to a UIImage.
    public static let dataToImageMapper = BidirectionalMapper<Data, UIImage>(
        forward: { data in
            guard let image = UIImage(data: data) else {
                throw CacheError.conversionError
            }
            return image
        },
        reverse: { image in
            guard let data = image.pngData() else {
                throw CacheError.conversionError
            }
            return data
        })
    #elseif os(OSX)
    /// Map from a Data to a NSImage.
    static let dataToImageMapper = BidirectionalMapper<Data, NSImage>(
        forward: { data in
            guard let image = NSImage(data: data) else {
                throw CacheError.conversionError
            }
            return image
        },
        reverse: { image in
            guard let data = image.tiffRepresentation else {
                throw CacheError.conversionError
            }
            return data
    })
    #endif
}
