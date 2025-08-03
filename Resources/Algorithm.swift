//
//  Algorithm.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

package import Foundation

import CryptoKit

package struct Algorithm {
    package struct Key: @unchecked Sendable {
        fileprivate let symmetric: SymmetricKey
        
        package init() {
            symmetric = .init(size: .bits256)
        }
    }
    
    package init() { }
    
    package func seal(_ data: Data, using key: Key) throws -> Data {
        try ChaChaPoly.seal(data, using: key.symmetric).combined
    }
    
    package func open(_ data: Data, using key: Key) throws -> Data {
        try ChaChaPoly.open(.init(combined: data), using: key.symmetric)
    }
}

// MARK: - Algorithm.Key
package extension Algorithm.Key {
    var base64: String {
        symmetric.withUnsafeBytes { buffer in
            Data(buffer).base64EncodedString()
        }
    }
    
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        symmetric = .init(data: data)
    }
}

// MARK: - Algorithm.Key
extension Algorithm.Key: Codable {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        
        symmetric = .init(data: data)
    }
    
    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(symmetric.withUnsafeBytes(Data.init(_:)))
    }
}
