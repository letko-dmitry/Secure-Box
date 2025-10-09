//
//  Algorithm.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

package import CryptoKit

package struct Algorithm {
    package struct Key: @unchecked Sendable {
        package let symmetric: SymmetricKey
        
        package init(symmetric: SymmetricKey) {
            self.symmetric = symmetric
        }
    }
    
    package init() { }
}
