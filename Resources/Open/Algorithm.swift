//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

import Compression
import CryptoKit
import Foundation
import SecureBoxTypes

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
            // A raw buffer specializes `SealedBox(combined:)` smaller than `Data` does, and the box copies the bytes anyway.
            let box = try unsafe (consume combined).withUnsafeBytes(AES.GCM.SealedBox.init(combined:))

            return try AES.GCM.open(box, using: key)
        }

        let nonceSize = 12, tagSize = 16

        // Keeps the accesses below in bounds, the sizes themselves are validated by `Nonce` and `open`.
        guard combined.count >= nonceSize &+ tagSize else { throw CryptoKitError.incorrectParameterSize }

        let start = combined.startIndex, end = combined.endIndex
        let nonce = try AES.GCM.Nonce(copying: combined.bytes.extracting(first: nonceSize))
        // A copy on the stack: the tag cannot stay borrowed from `combined` while the message in it is decrypted.
        let tag = combined.bytes.load(fromByteOffset: combined.count &- tagSize, as: [16 of UInt8].self)
        // swiftformat:disable:next redundantParens - `consume combined[…]` does not compile
        var message = (consume combined)[start &+ nonceSize..<end &- tagSize]
        var span = message.mutableBytes

        try AES.GCM.open(inPlace: &span, using: key, nonce: nonce, tag: tag.span.bytes)

        return message
    }

    /** Reads what `seal` writes, see `Algorithm.format`: the plaintext size, the method (as is, LZ4 or LZFSE), then the plaintext, copied or decoded straight into a buffer of that size. */
    func decompress(_ payload: borrowing Data) throws -> Data {
        let bytes = payload.bytes, methodOffset = MemoryLayout<UInt64>.size, headerSize = methodOffset &+ MemoryLayout<UInt8>.size

        guard bytes.byteCount >= headerSize else { throw cocoaError(.fileReadCorruptFile) }

        let size = Int(UInt64(bigEndian: bytes.load(fromByteOffset: 0, as: UInt64.self)))
        let body = bytes.extracting(droppingFirst: headerSize)
        let algorithm: compression_algorithm

        switch bytes.load(fromByteOffset: methodOffset, as: UInt8.self) {
        case Self.stored:
            guard body.byteCount == size else { throw cocoaError(.fileReadCorruptFile) }

            return body.withUnsafeBytes { unsafe Data($0) }

        case Self.lz4:
            algorithm = COMPRESSION_LZ4_RAW

        case Self.lzfse:
            algorithm = COMPRESSION_LZFSE

        default:
            throw cocoaError(.fileReadCorruptFile)
        }

        var plaintext = Data(count: size)
        var output = plaintext.mutableBytes
        let written = output.withUnsafeMutableBytes { output in
            body.withUnsafeBytes { input in
                guard let destination = output.baseAddress, let source = input.baseAddress else { return 0 }

                return unsafe compression_decode_buffer(
                    destination.assumingMemoryBound(to: UInt8.self),
                    output.count,
                    source.assumingMemoryBound(to: UInt8.self),
                    input.count,
                    nil,
                    algorithm
                )
            }
        }

        guard written == size else { throw cocoaError(.fileReadCorruptFile) }

        return plaintext
    }
}

// MARK: - CocoaError
/** Every `CocoaError` this module throws, out of line: built at each `throw`, one costs about 100 bytes of code. The `NSError` is the one `CocoaError.error(_:)` makes, with less code to make it. */
@inline(never)
func cocoaError(_ code: CocoaError.Code) -> any Error {
    NSError(domain: NSCocoaErrorDomain, code: code.rawValue, userInfo: nil)
}

// MARK: - SymmetricKey
extension SymmetricKey {
    /** Initializers consume their parameters by default, but `base64` is only read. */
    init?(base64: borrowing String) {
        guard let data = Data(base64Encoded: base64) else { return nil }

        self.init(data: data)
    }
}
