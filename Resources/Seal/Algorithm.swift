//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

package import Foundation
package import SecureBoxTypes

import CryptoKit

package extension SecureBoxTypes.Algorithm {
    /** The version of the layout `seal` writes and `open` reads. Bump it with any change to either: the cache is named after it, so everything is sealed again. */
    static let format = 3

    func seal(_ data: Data, using key: Key) throws -> Data {
        // The plaintext size goes first, big-endian, so opening decompresses straight into a buffer of that size.
        let header = unsafe withUnsafeBytes(of: UInt64(data.count).bigEndian, Data.init(_:))
        // swiftlint:disable:next legacy_objc_type
        let compressed = try (data as NSData).compressed(using: .lzfse) as Data

        // `combined` is missing only for a nonce other than the default 12 bytes.
        guard let combined = try AES.GCM.seal(header + compressed, using: key.symmetric).combined else { throw CryptoKitError.incorrectParameterSize }

        return combined
    }
}

// MARK: - Algorithm.Key
package extension SecureBoxTypes.Algorithm {
    /** Lives here rather than in `SecureBoxTypes`, so apps don't ship its metadata: opening needs only the `SymmetricKey`. */
    struct Key: Sendable {
        let symmetric: SymmetricKey
    }
}

package extension SecureBoxTypes.Algorithm.Key {
    /** `SymmetricKey` accepts data of any length, so the expected one has to be enforced by hand. */
    fileprivate static let size: SymmetricKeySize = .bits256

    var base64: String {
        unsafe symmetric.withUnsafeBytes { buffer in
            unsafe Data(buffer).base64EncodedString()
        }
    }

    init() {
        self.init(symmetric: .init(size: Self.size))
    }
}

// MARK: - Algorithm.Key: Decodable
extension SecureBoxTypes.Algorithm.Key: Decodable {
    package init(from decoder: borrowing any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        let size = Self.size.bitCount / 8

        guard data.count == size else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a key of \(size) bytes, decoded \(data.count)")
        }

        self.init(symmetric: .init(data: data))
    }
}
 
// MARK: - Algorithm.Key: Encodable
extension SecureBoxTypes.Algorithm.Key: Encodable {
    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(unsafe symmetric.withUnsafeBytes(Data.init(_:)))
    }
}
