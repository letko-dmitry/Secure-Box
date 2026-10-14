//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

import Foundation
import SecureBoxTypes
import CryptoKit
import Compression

extension SecureBoxTypes.Algorithm {
    @inline(always)
    func open(_ data: consuming Data, using key: SymmetricKey) throws -> Data {
        try decompress(decrypt(data, using: key))
    }
}

// MARK: - private
private extension SecureBoxTypes.Algorithm {
    /** `combined` is consumed, so the 27 releases decrypt it in place and older ones release it once `SealedBox` copies it. */
    func decrypt(_ combined: consuming Data, using key: SymmetricKey) throws -> Data {
        guard #available(anyAppleOS 27, *) else {
            // A raw buffer specializes `SealedBox(combined:)` far smaller than `Data` does, and the box copies the bytes anyway.
            let box = try unsafe (consume combined).withUnsafeBytes(ChaChaPoly.SealedBox.init(combined:))

            return try ChaChaPoly.open(box, using: key)
        }

        let nonceSize = 12, tagSize = 16

        // Keeps the accesses below in bounds, the sizes themselves are validated by `Nonce` and `open`.
        guard combined.count >= nonceSize &+ tagSize else { throw CryptoKitError.incorrectParameterSize }

        let start = combined.startIndex, end = combined.endIndex
        let nonce = try ChaChaPoly.Nonce(copying: combined.bytes.extracting(first: nonceSize))
        // A copy on the stack: the tag cannot stay borrowed from `combined` while the message in it is decrypted.
        let tag = combined.bytes.load(fromByteOffset: combined.count &- tagSize, as: [16 of UInt8].self)
        var message = (consume combined)[start &+ nonceSize ..< end &- tagSize]
        var span = message.mutableBytes

        try ChaChaPoly.open(inPlace: &span, using: key, nonce: nonce, tag: tag.span.bytes)

        return message
    }

    /** Reads what `seal` writes, see `Algorithm.format`: the plaintext size, then LZFSE decoded straight into a buffer of that size. */
    func decompress(_ payload: borrowing Data) throws -> Data {
        let bytes = payload.bytes, headerSize = MemoryLayout<UInt64>.size

        guard bytes.byteCount >= headerSize else { throw CocoaError.error(.fileReadCorruptFile) }

        let size = Int(UInt64(bigEndian: bytes.load(fromByteOffset: 0, as: UInt64.self)))
        let compressed = bytes.extracting(droppingFirst: headerSize)
        var plaintext = Data(count: size)
        var output = plaintext.mutableBytes
        let written = output.withUnsafeMutableBytes { output in
            compressed.withUnsafeBytes { input in
                guard let destination = output.baseAddress, let source = input.baseAddress else { return 0 }

                return unsafe compression_decode_buffer(
                    destination.assumingMemoryBound(to: UInt8.self), output.count,
                    source.assumingMemoryBound(to: UInt8.self), input.count,
                    nil, COMPRESSION_LZFSE
                )
            }
        }

        guard written == size else { throw CocoaError.error(.fileReadCorruptFile) }

        return plaintext
    }
}

// MARK: - SymmetricKey
extension SymmetricKey {
    /** Initializers consume their parameters by default, but `base64` is only read. */
    init?(base64: borrowing String) {
        guard let data = Data(base64Encoded: base64) else { return nil }

        self.init(data: data)
    }
}
