//
//  PluginError.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

enum PluginError: Error {
    case sourceModuleUnavailable(String)
    case directoryContentUnavailable(URL)
}

// MARK: - CustomStringConvertible
extension PluginError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .sourceModuleUnavailable(name):
            return "Target '\(name)' does not provide a source module"

        case let .directoryContentUnavailable(url):
            return "Unable to enumerate the content of \(url.path(percentEncoded: false))"
        }
    }
}
