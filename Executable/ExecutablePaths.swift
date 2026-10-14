//
//  ExecutablePaths.swift
//
//
//  Created by Dzmitry Letko on 24/09/2023.
//

import Foundation
import SecureBoxTypes
import SecureBoxSeal

struct ExecutablePaths {
    struct Directories {
        let root: URL
        let box: URL
    }

    struct Files {
        let cache: URL
        let code: URL
    }

    let directories: Directories
    let files: Files

    init(task: borrowing ExecutableTask) {
        directories = .init(
            root: task.root,
            box: task.box
        )
        files = .init(
            cache: directories.root.appending(path: "cache-\(Algorithm.format).json", directoryHint: .notDirectory),
            code: task.code
        )
    }
}
