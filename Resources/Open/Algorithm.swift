//
//  Algorithm.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

import Foundation
import SecureBoxTypes
import Compression
import CryptoKit

extension SecureBoxTypes.Algorithm {
    func open(_ data: Data, using key: Key) throws -> Data {
        let compressed = try ChaChaPoly.open(.init(combined: data), using: key.symmetric)
        
        let bufferSize = compressed.count
        var bufferIndex = 0
        
        let decompressing = try InputFilter(.decompress, using: .lzfse) { length in
            let length = min(length, bufferSize - bufferIndex)
            let subdata = compressed.subdata(in: bufferIndex ..< bufferIndex + length)
            
            bufferIndex += length
            
            return subdata
        }
        
        let decompressionPageSize = min(65_536, compressed.count)
        var decompressed = Data()
        
        while let page = try decompressing.readData(ofLength: decompressionPageSize) {
            decompressed.append(page)
        }
        
        return decompressed
    }
}

// MARK: - Algorithm.Key
extension SecureBoxTypes.Algorithm.Key {
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        self.init(symmetric: .init(data: data))
    }
}
