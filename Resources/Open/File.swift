//
//  File.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

public import Foundation
public import SecureBoxTypes

import CryptoKit

public extension File {
    func open() throws -> Data {
        guard let fileUrl = path.url else { throw cocoaError(.fileNoSuchFile) }
        guard let key = SymmetricKey(base64: key) else { throw CryptoKitError.incorrectKeySize }
        
        return try Algorithm().open(Data(contentsOf: fileUrl, options: .uncached), using: key)
    }
}

// MARK: - File.Path
private extension File.Path {
    var url: URL? {
        bundle.url(forResource: name, withExtension: `extension`, subdirectory: subdirectory)
    }
}
