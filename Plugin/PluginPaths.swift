//
//  PluginPaths.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation

struct PluginPaths {
    struct Directories {
        let root: URL
        let output: URL
        let box: URL
        
        init(root: URL) {
            self.root = root
            self.output = root.appending(component: "Output", directoryHint: .isDirectory)
            self.box = output.appending(component: "Box", directoryHint: .isDirectory)
        }
    }
    
    struct Files {
        let code: URL
        let task: URL
    }
    
    let directories: Directories
    let files: Files
    
    init(root: URL) {
        directories = .init(root: root)
        files = .init(
            code: directories.output.appending(component: "Box.swift", directoryHint: .notDirectory),
            task: directories.root.appending(component: "task.json", directoryHint: .notDirectory)
        )
    }
    
    /** Builds the `Output/Box/<name>.dat` path for a sealed resource. */
    func output(name: String) -> URL {
        return directories.box.appending(component: "\(name).dat", directoryHint: .notDirectory)
    }
}
