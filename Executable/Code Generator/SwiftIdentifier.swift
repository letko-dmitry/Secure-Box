//
//  SwiftIdentifier.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

/** A Swift identifier derived from a file name, valid both where it is declared and where it is referenced. */
struct SwiftIdentifier {
    /** The identifier as it is referenced: `SecureBox.<name>`. */
    let name: String

    /** The identifier as it is declared, escaped when it would otherwise read as a keyword. */
    var declaration: String {
        Self.keywords.contains(name) ? "`\(name)`" : name
    }
}

extension SwiftIdentifier {
    init?(fileUrl: URL) {
        var components = fileUrl.deletingPathExtension().lastPathComponent.identifierComponents
        components.append(contentsOf: fileUrl.pathExtension.identifierComponents)

        guard let first = components.first else { return nil }

        let name = first.lowercasedHead + components.dropFirst().map(\.uppercasedHead).joined()

        guard let head = name.first else { return nil }

        // An identifier may not start with a digit, but it may start with an underscore.
        self.name = head.isNumber ? "_\(name)" : name
    }
}

// MARK: - private
private extension SwiftIdentifier {
    /**
     Reserved and contextual keywords.

     Escaping something that turns out not to be a keyword is harmless, so the set errs on the generous side.
     */
    static let keywords: Set<String> = [
        "Any", "Self", "actor", "any", "as", "associatedtype", "await", "borrowing", "break", "case", "catch",
        "class", "consume", "consuming", "continue", "convenience", "copy", "default", "defer", "deinit",
        "discard", "distributed", "do", "dynamic", "each", "else", "enum", "extension", "fallthrough", "false",
        "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "in", "indirect", "infix", "init",
        "inout", "internal", "is", "isolated", "lazy", "let", "macro", "mutating", "nil", "nonisolated",
        "nonmutating", "open", "operator", "optional", "override", "package", "postfix", "precedencegroup",
        "prefix", "private", "protocol", "public", "regex", "repeat", "required", "rethrows", "return", "self",
        "sending", "set", "some", "static", "struct", "subscript", "super", "switch", "throw", "throws", "true",
        "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet", "didSet"
    ]
}

// MARK: - String
private extension String {
    /**
     The receiver split on everything that cannot appear in an identifier.

     Underscores separate rather than survive, so that `my_file` reads as `myFile`.
     */
    var identifierComponents: [String] {
        components(separatedBy: CharacterSet.letters.union(.decimalDigits).inverted).filter { !$0.isEmpty }
    }

    /** Lowercases a component that carries no case of its own as a whole, and every other one by its head only. */
    var lowercasedHead: String {
        guard let first else { return self }
        guard contains(where: \.isLowercase) else { return lowercased() }

        return first.lowercased() + String(dropFirst())
    }

    /** The counterpart of `lowercasedHead`, preserving the casing the author chose within a component. */
    var uppercasedHead: String {
        guard let first else { return self }
        guard contains(where: \.isLowercase) else { return capitalized }

        return first.uppercased() + String(dropFirst())
    }
}
