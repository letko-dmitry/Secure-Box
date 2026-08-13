//
//  PluginScan.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

/** The outcome of looking for sealable files inside the box directories of a single target. */
struct PluginScan {
    /** Files that will be handed over to the executable. */
    let candidates: [URL]

    /** Every box directory that was found, including the ones that hold nothing sealable. */
    let directories: Set<URL>
}

// MARK: - URL
extension URL {
    /**
     A key that identifies the item no matter how its path was spelled.

     The build system and a directory enumerator do not agree on whether the path of a directory ends with a
     separator, so matching raw URLs would silently miss whole directories.
     */
    var attachmentKey: String {
        let path = standardizedFileURL.path(percentEncoded: false)

        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}
