//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

import Foundation
import SecureBoxTypes
import CryptoKit

extension SecureBoxTypes.Algorithm {
    @inline(always)
    func open(_ data: consuming Data, using key: SymmetricKey) throws -> Data {
        // swiftlint:disable:next legacy_objc_type
        try Data(referencing: (decrypt(data, using: key) as NSData).decompressed(using: .lzfse))
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
}

// MARK: - SymmetricKey
extension SymmetricKey {
    /** Initializers consume their parameters by default, but `base64` is only read. */
    init?(base64: borrowing String) {
        guard let data = Data(base64Encoded: base64) else { return nil }

        self.init(data: data)
    }
}
