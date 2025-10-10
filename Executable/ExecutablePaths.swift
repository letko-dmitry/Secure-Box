//
//  ExecutablePaths.swift
//  
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation

struct ExecutablePaths {
    struct Directories {
        let rootUrl: URL
        let boxUrl: URL
    }
    
    struct Files {
        let cacheUrl: URL
        let codeUrl: URL
    }
    
    let directories: Directories
    let files: Files
    
    init(task: borrowing ExecutableTask) {
        directories = .init(
            rootUrl: .init(filePath: task.root, directoryHint: .isDirectory),
            boxUrl: .init(filePath: task.box, directoryHint: .isDirectory)
        )
        files = .init(
            cacheUrl: directories.rootUrl.appending(path: "cache.json", directoryHint: .notDirectory),
            codeUrl: .init(filePath: task.code, directoryHint: .notDirectory)
        )
    }
}
