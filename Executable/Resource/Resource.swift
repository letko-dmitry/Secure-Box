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
        enum ResourceCandidateError: Error {
            case unknownContentModificationDate(URL)
        }
        
        let url: URL
        let modified: Date
        
        init(url: URL) throws {
            let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])

            guard let modified = resources.contentModificationDate else {
                throw ResourceCandidateError.unknownContentModificationDate(url)
            }
            
            self.url = url
            self.modified = modified
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
            NSLog("Resource.Input read content type key error: \(error)")
        }
        
        switch url.pathExtension {
        case "json": return .json
        default: return nil
        }
    }
}
