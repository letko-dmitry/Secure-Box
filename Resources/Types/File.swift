//
//  File.swift
//  
//
//  Created by Dzmitry Letko on 24/09/2023.
//

public import Foundation

public struct File: Sendable {
    public struct Path: Sendable {
        package let name: String
        package let `extension`: String?
        package let subdirectory: String?
        package let bundle: Bundle
        
        public init(name: String, extension: String? = "dat", subdirectory: String? = nil, bundle: Bundle = .main) {
            self.name = name
            self.extension = `extension`
            self.subdirectory = subdirectory
            self.bundle = bundle
        }
    }
    
    package let path: Path
    package let key: String
    
    public init(path: Path, key: String) {
        self.path = path
        self.key = key
    }
}
