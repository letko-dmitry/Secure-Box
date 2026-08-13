//
//  CodeGeneratorError.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

enum CodeGeneratorError: Error {
    case unnameable(URL)
    case duplicates([String: [URL]])
}

// MARK: - CustomStringConvertible
extension CodeGeneratorError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .unnameable(url):
            return "Unable to derive a Swift name from '\(url.lastPathComponent)'. Rename the file so that it holds at least one letter or digit."

        case let .duplicates(duplicates):
            return duplicates
                .sorted { $0.key < $1.key }
                .map { name, urls in
                    let inputs = urls
                        .map { "'\($0.path(percentEncoded: false))'" }
                        .sorted()
                        .joined(separator: ", ")

                    return "\(inputs) all map to 'SecureBox.\(name)'. Give them distinct file names."
                }
                .joined(separator: "\n")
        }
    }
}
