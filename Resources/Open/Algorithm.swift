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
    func open(_ data: Data, using key: Key) throws -> Data {
        // swiftlint:disable:next legacy_objc_type
        try Data(referencing: (ChaChaPoly.open(.init(combined: data), using: key.symmetric) as NSData).decompressed(using: .lzfse))
    }
}

// MARK: - Algorithm.Key
extension SecureBoxTypes.Algorithm.Key {
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        self.init(symmetric: .init(data: data))
    }
}
