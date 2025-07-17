//
//  File.swift
//  
//
//  Created by Dzmitry Letko on 24/09/2023.
//
import Foundation
import Algorithms

public struct File: Sendable {
    public struct Path: Sendable {
        private let name: String
        private let `extension`: String?
        private let subdirectory: String?
        private let bundle: Bundle
        
        public init(name: String, extension: String? = "dat", subdirectory: String? = nil, bundle: Bundle = .main) {
            self.name = name
            self.extension = `extension`
            self.subdirectory = subdirectory
            self.bundle = bundle
        }
    }
    
    private let path: Path
    private let key: String
    
    public init(path: Path, key: String) {
        self.path = path
        self.key = key
    }
    
    public func open() throws -> Data {
        enum OpenError: Error {
            case invalidPath
            case invalidKey
        }

        guard let fileUrl = path.url else { throw OpenError.invalidPath }
        guard let key = Algorithm.Key(base64: key) else { throw OpenError.invalidKey }
        
        return try Algorithm().open(Data(contentsOf: fileUrl, options: .uncached), using: key)
    }
}

// MARK: - File.Path
private extension File.Path {
    var url: URL? {
        func url(in bundle: Bundle) -> URL? {
            bundle.url(forResource: name, withExtension: `extension`, subdirectory: subdirectory)
        }
        
        if let url = url(in: bundle) { return url }
        
        return bundle
            .urls(forResourcesWithExtension: "bundle", subdirectory: nil)?
            .lazy
            .compactMap { Bundle(url: $0) }
            .firstNonNil(url(in:))
    }
}
