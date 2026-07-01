//
//  ExecutableTask.swift
//
//
//  Created by Dzmitry Letko on 25/09/2023.
//

import Foundation

struct ExecutableTask: Decodable {
    struct Resource: Decodable {
        let input: URL
        let output: URL
    }
    
    let root: URL
    let code: URL
    let box: URL
    let resources: [Resource]
}
