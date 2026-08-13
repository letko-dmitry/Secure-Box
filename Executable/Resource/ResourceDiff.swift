//
//  ResourceDiff.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation

struct ResourceDiff {
    let all: [Resource]
    let encrypt: [Resource]
    let delete: [Resource]

    var hasChanges: Bool {
        !(encrypt.isEmpty && delete.isEmpty)
    }
}

enum ResourceDiffBuilder {
    static func make(candidates: [ResourceCandidate], cached: [Resource]) -> ResourceDiff {
        let fileManager = FileManager.default
        let candidates = Set(candidates)

        // A cached resource whose sealed file is gone has to be sealed again, so it cannot count as cached.
        let cached = cached.filter { resource in
            fileManager.fileExists(atPath: resource.output.url.path(percentEncoded: false))
        }
        let updated = candidates.subtracting(cached.map(ResourceCandidate.init(resource:)))

        var all: [Resource] = []
        all.reserveCapacity(candidates.count)

        var encrypt: [Resource] = []
        encrypt.reserveCapacity(updated.count)

        var delete: [Resource] = []

        updated.forEach { candidate in
            let resource = Resource(candidate: candidate)

            all.append(resource)
            encrypt.append(resource)
        }

        cached.forEach { resource in
            if candidates.contains(.init(resource: resource)) {
                all.append(resource)
            } else {
                delete.append(resource)
            }
        }

        return .init(all: all, encrypt: encrypt, delete: delete)
    }
}
