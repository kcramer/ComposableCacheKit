//
//  Crypto.swift
//  ComposableCacheKit
//
//  Created by Kevin on 12/15/18.
//  Copyright © 2018 Kevin. All rights reserved.
//

import Foundation
import CommonCrypto

/// Provides crypto helper functions.
internal struct Crypto {
    /// Returns the SHA256 hash of a Data as a Data value.
    internal static func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        let bytes = [UInt8](data)
        CC_SHA256(bytes, CC_LONG(data.count), &hash)
        return Data(hash)
    }

    /// Returns the SHA256 hash of a string as a hexadecimal string.
    internal static func sha256(string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        let hash = Crypto.sha256(data: data)
        let hashString = hash.map { (byte) -> String in
            return String(format: "%02x", byte)
            }.joined()
        return hashString
    }
}
