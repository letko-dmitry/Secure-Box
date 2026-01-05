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
        let data = try Data(contentsOf: input.url, options: .uncached)
        
        switch input.type {
        case UTType.json:
            return try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: data))

        case UTType.propertyList:
            return try unsafe PropertyListSerialization.data(fromPropertyList: PropertyListSerialization.propertyList(from: data, format: nil), format: .binary, options: 0)

        default:
            return data
        }
    }
}
