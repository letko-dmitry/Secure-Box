//
//  ResourceCandidate.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

import Foundation

struct ResourceCandidate: Hashable {
    let input: Resource.Input
    let outputUrl: URL
    
    init(input: URL, output: URL) throws {
        self.input = try .init(url: input)
        self.outputUrl = output
    }
    
    init(resource: borrowing Resource) {
        input = resource.input
        outputUrl = resource.output.url
    }
}

extension ResourceCandidate {
    init(resource: borrowing ExecutableTask.Resource) throws {
        try self.init(input: resource.input, output: resource.output)
    }
}
