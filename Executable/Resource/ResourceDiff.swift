//
//  ResourceDiff.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation
import SecureBoxSeal
import SecureBoxTypes

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
        let algorithm = Algorithm()
        let candidates = Set(candidates)

        // A cached resource counts only while its sealed file opens with its key. The file may be gone, or sealed again
        // under another key: a build at another format seals into the same files, with keys of its own.
        let cached = cached.filter { resource in
            guard let sealed = try? Data(contentsOf: resource.output.url, options: .uncached) else { return false }

            return algorithm.opens(sealed, using: resource.output.key)
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
