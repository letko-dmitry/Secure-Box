import Foundation
import SecureBoxTypes
import SecureBoxSeal

@main
enum Executable {
    static func main() async throws {
        let taskUrl = URL(filePath: String(CommandLine.arguments[1]), directoryHint: .notDirectory)
        let taskData = try Data(contentsOf: taskUrl, options: .uncached)
        let task = try JSONDecoder().decode(ExecutableTask.self, from: taskData)
        
        try await execute(task: task)
    }
}

// MARK: - private
private extension Executable {
    static func execute(task: ExecutableTask) async throws {
        let paths = ExecutablePaths(task: task)
        
        async let (cache, cacheCorrupted) = Cache.read(from: paths.files.cacheUrl)
        async let candidates = try task.resources.map(ResourceCandidate.init(resource:))
        
        let diff = try await ResourceDiffBuilder.make(
            candidates: candidates,
            cached: cache?.resources ?? []
        )
        
        let (reset, hasCache) = await (cacheCorrupted, cache != nil)
        
        if diff.hasChanges || !hasCache {
            try await withThrowingDiscardingTaskGroup { group in
                if diff.hasChanges {
                    group.addTask {
                        try await apply(diff: diff, clean: reset, at: paths.directories.boxUrl)
                    }
                }
                
                group.addTask {
                    Cache(resources: diff.all).write(to: paths.files.cacheUrl)
                }
                
                group.addTask {
                    try CodeGenerator(fileUrl: paths.files.codeUrl).generate(for: diff.all)
                }
            }
        }
    }
}

// MARK: - private
private extension Executable {
    static func apply(diff: ResourceDiff, clean: Bool, at fileUrl: URL) async throws {
        let fileManager = FileManager.default
        
        do {
            if clean {
                try fileManager.removeItem(at: fileUrl)
            } else {
                try diff.delete.forEach { resource in
                    try fileManager.removeItem(at: resource.output.url)
                }
            }
        } catch {
            NSLog("Box cleanup at: \(fileUrl), error: \(error)")
        }
        
        try fileManager.createDirectory(at: fileUrl, withIntermediateDirectories: true)
        
        try await encrypt(resources: diff.encrypt)
    }
    
    static func encrypt(resources: [Resource]) async throws {
        try await withThrowingDiscardingTaskGroup { group in
            resources.forEach { resource in
                group.addTask {
                    let data = try ResourceReader.read(input: resource.input)
                    let algorithm = Algorithm()
                    try algorithm.seal(data, using: resource.output.key).write(to: resource.output.url)
                }
            }
        }
    }
}
