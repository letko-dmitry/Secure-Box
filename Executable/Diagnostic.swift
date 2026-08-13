//
//  Diagnostic.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

/**
 Build time diagnostics.

 Xcode recognises `path:line:column: severity: message` in the output of a build tool and turns it into a
 clickable entry in the build log; `swift build` prints it verbatim.

 Anything that can be told from the list of files alone belongs to the plugin instead: the plugin runs on
 every build, while this tool is skipped as long as its inputs are unchanged.
 */
enum Diagnostic {
    enum Severity: String {
        case error
        case warning
        case note
    }

    static func emit(_ severity: Severity, _ message: String, file fileUrl: URL? = nil) {
        let location = fileUrl.map { "\($0.path(percentEncoded: false)):1:1: " } ?? ""

        // A failing write can only mean that the channel this very message would be reported on is gone, so
        // there is nothing to do about it. An error is still carried by the exit code of the tool on its own.
        try? FileHandle.standardError.write(contentsOf: Data("\(location)\(severity.rawValue): \(message)\n".utf8))
    }

    static func error(_ message: String, file fileUrl: URL? = nil) {
        emit(.error, message, file: fileUrl)
    }

    static func warning(_ message: String, file fileUrl: URL? = nil) {
        emit(.warning, message, file: fileUrl)
    }

    static func note(_ message: String, file fileUrl: URL? = nil) {
        emit(.note, message, file: fileUrl)
    }
}
