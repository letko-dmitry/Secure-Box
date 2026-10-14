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
    /** `data` is consumed, so the ciphertext is released as soon as `SealedBox` copies it, not after decryption. */
    @inline(always)
    func open(_ data: consuming Data, using key: SymmetricKey) throws -> Data {
        // swiftlint:disable:next legacy_objc_type
        try Data(referencing: (ChaChaPoly.open(.init(combined: data), using: key) as NSData).decompressed(using: .lzfse))
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
