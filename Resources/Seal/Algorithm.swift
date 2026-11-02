//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

package import Foundation
package import SecureBoxTypes

import Compression
import CryptoKit

package extension SecureBoxTypes.Algorithm {
    /** The version of the layout `seal` writes and `open` reads. Bump it with any change to either: the cache is named after it, so everything is sealed again. */
    static let format = 4

    func seal(_ data: Data, using key: Key) throws -> Data {
        var method = Self.stored
        var body = data

        // The smallest form wins. Each has to be strictly smaller, so a tie goes to what opens fastest.
        if let encoded = encode(data, using: COMPRESSION_LZ4_RAW), encoded.count < body.count {
            (method, body) = (Self.lz4, encoded)
        }
        if let encoded = encode(data, using: COMPRESSION_LZFSE), encoded.count < body.count {
            (method, body) = (Self.lzfse, encoded)
        }

        // The plaintext size, big-endian, then the method, so opening knows both before it allocates the plaintext.
        var message = unsafe withUnsafeBytes(of: UInt64(data.count).bigEndian, Data.init(_:))
        message.append(method)
        message.append(body)

        // `combined` is missing only for a nonce other than the default 12 bytes.
        guard let combined = try AES.GCM.seal(message, using: key.symmetric).combined else { throw CryptoKitError.incorrectParameterSize }

        return combined
    }

    /** Whether `sealed` was sealed with `key`: AES-GCM authenticates a sealed file under its own key only. */
    func opens(_ sealed: Data, using key: Key) -> Bool {
        (try? AES.GCM.open(AES.GCM.SealedBox(combined: sealed), using: key.symmetric)) != nil
    }
}

// MARK: - private
private extension SecureBoxTypes.Algorithm {
    /** The buffer form `decompress` reads back. `nil` when the encoder fails, as it does when its output would not fit in the size of `data`: storing it as is would be no larger. */
    func encode(_ data: Data, using algorithm: compression_algorithm) -> Data? {
        // The encoders refuse a destination under 128 bytes, whatever they would write.
        var output = Data(count: Swift.max(data.count, 128))
        var span = output.mutableBytes
        let count = span.withUnsafeMutableBytes { output in
            data.bytes.withUnsafeBytes { input in
                guard let destination = output.baseAddress, let source = input.baseAddress else { return 0 }

                return unsafe compression_encode_buffer(
                    destination.assumingMemoryBound(to: UInt8.self),
                    output.count,
                    source.assumingMemoryBound(to: UInt8.self),
                    input.count,
                    nil,
                    algorithm
                )
            }
        }

        guard count > 0 else { return nil }

        output.count = count

        return output
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
