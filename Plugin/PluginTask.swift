//
//  PluginTask.swift
//  
//
//  Created by Dzmitry Letko on 25/09/2023.
//

import Foundation

struct PluginTask: Encodable {
    struct Resource: Encodable {
        let input: URL
        let output: URL
    }

    let root: URL
    let code: URL
    let box: URL
    let resources: [Resource]
}
