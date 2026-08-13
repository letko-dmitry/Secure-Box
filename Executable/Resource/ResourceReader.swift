//
//  ResourceReader.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

import Foundation
import UniformTypeIdentifiers

enum ResourceReader {
    static func read(input: Resource.Input) throws -> Data {
        let data: Data

        do {
            data = try Data(contentsOf: input.url, options: .uncached)
        } catch {
            throw ResourceError.unreadable(input.url, error)
        }

        guard !data.isEmpty else {
            Diagnostic.warning("The file is empty and is sealed as is.", file: input.url)

            return data
        }

        do {
            return try normalize(data, as: input.type)
        } catch {
            throw ResourceError.malformed(input.url, error)
        }
    }
}

// MARK: - private
private extension ResourceReader {
    /**
     Re-encodes structured formats into their most compact representation.

     The round trip is not lossless: the order of the keys, the formatting and any duplicate keys are lost.
     */
    static func normalize(_ data: Data, as type: UTType?) throws -> Data {
        switch type {
        case UTType.json:
            return try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]), options: [.fragmentsAllowed])

        case UTType.propertyList:
            return try unsafe PropertyListSerialization.data(fromPropertyList: PropertyListSerialization.propertyList(from: data, format: nil), format: .binary, options: 0)

        default:
            return data
        }
    }
}
