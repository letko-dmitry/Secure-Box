//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

package import Foundation
package import SecureBoxTypes

import CryptoKit
import Compression

package extension SecureBoxTypes.Algorithm {
    func seal(_ data: Data, using key: Key) throws -> Data {
        var compressed = Data()
        
        let compressionPageSize = 65_536
        let compression = try OutputFilter(.compress, using: .lzfse) { data in
            if let data {
                compressed.append(data)
            }
        }
        
        let bufferSize = data.count
        var bufferIndex = 0
        
        while true {
            let length = min(compressionPageSize, bufferSize - bufferIndex)
            
            if length == 0 {
                try compression.finalize()
                
                break
            }
            
            let subdata = data.subdata(in: bufferIndex ..< bufferIndex + length)
            
            bufferIndex += length
            
            try compression.write(subdata)
        }
        
        return try ChaChaPoly.seal(compressed, using: key.symmetric).combined
    }
}

// MARK: - Algorithm.Key
package extension SecureBoxTypes.Algorithm.Key {
    var base64: String {
        unsafe symmetric.withUnsafeBytes { buffer in
            unsafe Data(buffer).base64EncodedString()
        }
    }
    
    init() {
        self.init(symmetric: .init(size: .bits256))
    }
}

// MARK: - Algorithm.Key: Decodable
extension SecureBoxTypes.Algorithm.Key: Decodable {
    package init(from decoder: borrowing any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        
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
