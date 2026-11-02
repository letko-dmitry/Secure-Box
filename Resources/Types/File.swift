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
        /** Looked up once, when the path is made; `nil` when the bundle has no such resource. */
        @usableFromInline package let filePath: String?
        
        @inline(always)
        @export(implementation)
        public init(name: String, extension: String? = "dat", subdirectory: String? = nil, bundle: Bundle = .main) {
            filePath = Self.lookup(name: name, extension: `extension`, subdirectory: subdirectory, bundle: bundle)
        }

        /**
         Out of line, so each resource's inlined initializer is a single call rather than the whole bundle lookup. `bundle` is
         consumed: the initializer owns it, so it is handed over instead of being released after the call.
         */
        @usableFromInline
        @inline(never)
        package static func lookup(name: String, extension: String?, subdirectory: String?, bundle: consuming Bundle) -> String? {
            bundle.path(forResource: name, ofType: `extension`, inDirectory: subdirectory)
        }
    }
    
    @usableFromInline package let path: Path
    @usableFromInline package let key: String
    
    @inline(always)
    @export(implementation)
    public init(path: Path, key: String) {
        self.path = path
        self.key = key
    }
}
