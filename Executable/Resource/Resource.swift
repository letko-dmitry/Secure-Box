//
//  Resource.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation
import UniformTypeIdentifiers
import SecureBoxTypes
import SecureBoxSeal

struct Resource: Codable {
    struct Input: Codable, Hashable {
        let url: URL
        let modified: Date
        let size: Int

        init(url: URL) throws {
            let values: URLResourceValues

            do {
                values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            } catch {
                throw ResourceError.unreachable(url, error)
            }

            guard let modified = values.contentModificationDate else {
                throw ResourceError.unknownContentModificationDate(url)
            }
            guard let size = values.fileSize else {
                throw ResourceError.unknownFileSize(url)
            }

            self.url = url
            self.modified = modified
            self.size = size
        }
    }

    struct Output: Codable {
        let url: URL
        let key: Algorithm.Key

        init(url: URL) {
            self.url = url
            self.key = .init()
        }
    }

    let input: Input
    let output: Output

    init(candidate: borrowing ResourceCandidate) {
        self.input = candidate.input
        self.output = .init(url: candidate.outputUrl)
    }
}

extension Resource.Input {
    var type: UTType? {
        do {
            if let type = try url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                return type
            }
        } catch {
            Diagnostic.note("Unable to read the content type: \(error)", file: url)
        }

        switch url.pathExtension.lowercased() {
        case "json": return .json
        case "plist": return .propertyList
        default: return nil
        }
    }
}
