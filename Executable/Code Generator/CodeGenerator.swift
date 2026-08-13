//
//  CodeGenerator.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

import Foundation
import SecureBoxTypes
import SecureBoxSeal

struct CodeGenerator {
    let fileUrl: URL

    func generate(for resources: [Resource]) throws {
        let declarations = try declarations(for: resources)
        let code = """
            import Foundation
            import ObfuscateMacro
            import SecureBoxTypes

            enum SecureBox {
            \(declarations.map(\.code).joined(separator: "\n\n"))
            }
            """

        try FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
        try code.write(to: fileUrl, atomically: true, encoding: .utf8)
    }
}

// MARK: - private
private extension CodeGenerator {
    struct Declaration {
        let identifier: SwiftIdentifier
        let resource: Resource
    }

    /** Names every resource and refuses to emit code that would not compile. */
    func declarations(for resources: [Resource]) throws -> [Declaration] {
        let declarations: [Declaration] = try resources.map { resource in
            guard let identifier = SwiftIdentifier(fileUrl: resource.input.url) else {
                throw CodeGeneratorError.unnameable(resource.input.url)
            }

            return .init(identifier: identifier, resource: resource)
        }

        let duplicates = Dictionary(grouping: declarations, by: \.identifier.name).filter { $0.value.count > 1 }

        guard duplicates.isEmpty else {
            throw CodeGeneratorError.duplicates(duplicates.mapValues { $0.map(\.resource.input.url) })
        }

        return declarations
    }
}

// MARK: - CodeGenerator.Declaration
private extension CodeGenerator.Declaration {
    var code: String {
        """
            static let \(identifier.declaration) = SecureBoxTypes.File(
                path: .init(
                    name: \(resource.output.name.swiftLiteral)
                ),
                key: #ObfuscatedString(\(resource.output.key.base64.swiftLiteral))
            )
        """
    }
}

// MARK: - Resource.Output
private extension Resource.Output {
    var name: String {
        url.deletingPathExtension().lastPathComponent
    }
}

// MARK: - String
private extension String {
    /** The receiver as a Swift string literal, quotes included. */
    var swiftLiteral: String {
        var escaped = ""
        escaped.reserveCapacity(count + 2)

        unicodeScalars.forEach { scalar in
            switch scalar {
            case "\\": escaped += #"\\"#
            case "\"": escaped += #"\""#
            case "\n": escaped += #"\n"#
            case "\r": escaped += #"\r"#
            case "\t": escaped += #"\t"#
            case "\0": escaped += #"\0"#
            default: escaped.unicodeScalars.append(scalar)
            }
        }

        return "\"\(escaped)\""
    }
}
