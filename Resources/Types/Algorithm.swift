//
//  Algorithm.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

package struct Algorithm {
    package init() { }
}

// MARK: - Algorithm methods
/** How the plaintext follows its size in a sealed file: the byte `seal` writes and `open` reads. Constants rather than an enum, so apps don't ship its metadata. */
package extension Algorithm {
    @inlinable
    static var stored: UInt8 {
        0
    }

    @inlinable
    static var lz4: UInt8 {
        1
    }

    @inlinable
    static var lzfse: UInt8 {
        2
    }
}
