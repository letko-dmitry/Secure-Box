//
//  Cache.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation

struct Cache: Codable {
    let resources: [Resource]
}

extension Cache {
    static func read(from fileUrl: URL) -> (cache: Cache?, corrupted: Bool) {
        do {
            let data = try Data(contentsOf: fileUrl, options: .uncached)
            let cache = try JSONDecoder().decode(Cache.self, from: data)

            return (cache: cache, corrupted: false)
        } catch CocoaError.fileReadNoSuchFile {
            return (cache: nil, corrupted: false)
        } catch {
            Diagnostic.note("The cache is unusable and everything is sealed again: \(error)", file: fileUrl)

            return (cache: nil, corrupted: true)
        }
    }

    func write(to fileUrl: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(self)
            try data.write(to: fileUrl)
        } catch {
            Diagnostic.warning("The cache cannot be written, the next build will seal everything again: \(error)", file: fileUrl)
        }
    }
}
