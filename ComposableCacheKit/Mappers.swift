//
//  Mappers.swift
//  ComposableCacheKit
//
//  Created by Kevin on 11/30/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Promise

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
            return Promise(work: { fulfill, reject in
                if let string = String(data: data, encoding: .utf8) {
                    fulfill(string)
                } else {
                    reject(CacheError.conversionError)
                }
            })
        },
        reverse: { string in
            return Promise(work: { fulfill, reject in
                if let data = string.data(using: .utf8) {
                    fulfill(data)
                } else {
                    reject(CacheError.conversionError)
                }
            })
        })

    /// Map from a NSString to String.
    public static let nsstringToString = BidirectionalMapper<NSString, String>(
        forward: { nsstring in
            return Promise(value: nsstring as String)
        },
        reverse: { string in
            return Promise(value: string as NSString)
        })
}

extension BidirectionalMappers {
    #if os(iOS) || os(tvOS) || os(watchOS)
    /// Map from a Data to a UIImage.
    public static let dataToImageMapper = BidirectionalMapper<Data, UIImage>(
        forward: { data in
            return Promise(work: { fulfill, reject in
                if let image = UIImage(data: data) {
                    fulfill(image)
                } else {
                    reject(CacheError.conversionError)
                }
            })
        },
        reverse: { image in
            return Promise(work: { fulfill, reject in
                if let data = image.pngData() {
                    fulfill(data)
                } else {
                    reject(CacheError.conversionError)
                }
            })
        })
    #elseif os(OSX)
    /// Map from a Data to a NSImage.
    static let dataToImageMapper = BidirectionalMapper<Data, NSImage>(
        forward: { data in
            return Promise(work: { fulfill, reject in
                if let image = NSImage(data: data) {
                    fulfill(image)
                } else {
                    reject(CacheError.conversionError)
                }
            })
    },
        reverse: { image in
            return Promise(work: { fulfill, reject in
                if let data = image.tiffRepresentation {
                    fulfill(data)
                } else {
                    reject(CacheError.conversionError)
                }
            })
    })
    #endif
}
