//
//  ResourceError.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation

enum ResourceError: Error {
    case unreachable(URL, any Error)
    case unreadable(URL, any Error)
    case malformed(URL, any Error)
    case unknownContentModificationDate(URL)
    case unknownFileSize(URL)
}

// MARK: - CustomStringConvertible
extension ResourceError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .unreachable(url, error):
            return "\(url.path(percentEncoded: false)) cannot be reached, it may be a broken symbolic link: \(error)"

        case let .unreadable(url, error):
            return "\(url.path(percentEncoded: false)) cannot be read: \(error)"

        case let .malformed(url, error):
            return "\(url.path(percentEncoded: false)) is malformed and cannot be sealed: \(error)"

        case let .unknownContentModificationDate(url):
            return "\(url.path(percentEncoded: false)) has no content modification date, so it cannot be cached"

        case let .unknownFileSize(url):
            return "\(url.path(percentEncoded: false)) has no file size, so it cannot be cached"
        }
    }
}
