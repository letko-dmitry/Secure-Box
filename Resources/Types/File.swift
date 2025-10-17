//
//  File.swift
//  
//
//  Created by Dzmitry Letko on 24/09/2023.
//

public import Foundation

@frozen
public struct File: Sendable {
    @frozen
    public struct Path: Sendable {
        @usableFromInline package let name: String
        @usableFromInline package let `extension`: String?
        @usableFromInline package let subdirectory: String?
        @usableFromInline package let bundle: Bundle
        
        @inlinable
        public init(name: String, extension: String? = "dat", subdirectory: String? = nil, bundle: Bundle = .main) {
            self.name = name
            self.extension = `extension`
            self.subdirectory = subdirectory
            self.bundle = bundle
        }
    }
    
    @usableFromInline package let path: Path
    @usableFromInline package let key: String
    
    @inlinable
    public init(path: Path, key: String) {
        self.path = path
        self.key = key
    }
}
