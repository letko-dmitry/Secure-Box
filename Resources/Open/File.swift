//
//  File.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

public import SecureBoxTypes
public import Foundation

import Algorithms

public extension File {
    func open() throws -> Data {
        enum OpenError: Error {
            case invalidPath
            case invalidKey
        }

        guard let fileUrl = path.url else { throw OpenError.invalidPath }
        guard let key = Algorithm.Key(base64: key) else { throw OpenError.invalidKey }
        
        return try Algorithm().open(Data(contentsOf: fileUrl, options: .uncached), using: key)
    }
}

// MARK: - File.Path
private extension File.Path {
    var url: URL? {
        func url(in bundle: Bundle) -> URL? {
            bundle.url(forResource: name, withExtension: `extension`, subdirectory: subdirectory)
        }
        
        if let url = url(in: bundle) { return url }
        
        return bundle
            .urls(forResourcesWithExtension: "bundle", subdirectory: nil)?
            .lazy
            .compactMap { Bundle(url: $0) }
            .firstNonNil(url(in:))
    }
}
