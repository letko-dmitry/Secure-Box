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
        let candidates = Set(candidates)
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
