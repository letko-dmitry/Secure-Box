import Foundation
import SecureBoxTypes
import SecureBoxSeal

@main
enum Executable {
    static func main() async {
        guard let path = CommandLine.arguments.dropFirst().first else {
            Diagnostic.error("Expected the path of a task to be passed as the first argument")

            exit(EXIT_FAILURE)
        }

        do {
            let taskUrl = URL(filePath: path, directoryHint: .notDirectory)
            let taskData = try Data(contentsOf: taskUrl, options: .uncached)
            let task = try JSONDecoder().decode(ExecutableTask.self, from: taskData)

            try await execute(task: task)
        } catch {
            Diagnostic.error("\(error)")

            exit(EXIT_FAILURE)
        }
    }
}

// MARK: - private
private extension Executable {
    static func execute(task: ExecutableTask) async throws {
        let paths = ExecutablePaths(task: task)

        async let (cache, cacheCorrupted) = Cache.read(from: paths.files.cache)
        async let candidates = try task.resources.map(ResourceCandidate.init(resource:))

        let diff = try await ResourceDiffBuilder.make(
            candidates: candidates,
            cached: cache?.resources ?? []
        )

        let (reset, hasCache) = await (cacheCorrupted, cache != nil)

        // The generated code is an output of this tool as well, so a missing one has to be regenerated even
        // when nothing else changed.
        let hasCode = FileManager.default.fileExists(atPath: paths.files.code.path(percentEncoded: false))

        guard diff.hasChanges || !hasCache || !hasCode else { return }

        let all = diff.all.sorted(using: SortDescriptor(\.input.url.absoluteString, comparator: .lexical))

        try await withThrowingDiscardingTaskGroup { group in
            if diff.hasChanges {
                group.addTask {
                    try await apply(diff: diff, clean: reset, at: paths.directories.box)
                }
            }

            group.addTask {
                Cache(resources: all).write(to: paths.files.cache)
            }

            group.addTask {
                try CodeGenerator(fileUrl: paths.files.code).generate(for: all)
            }
        }
    }
}

// MARK: - private
private extension Executable {
    static func apply(diff: ResourceDiff, clean: Bool, at directoryUrl: URL) async throws {
        let fileManager = FileManager.default

        if clean {
            remove(directoryUrl, using: fileManager)
        } else {
            diff.delete.forEach { resource in
                remove(resource.output.url, using: fileManager)
            }
        }

        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true)

        try await encrypt(resources: diff.encrypt)
    }

    static func remove(_ fileUrl: URL, using fileManager: FileManager) {
        do {
            try fileManager.removeItem(at: fileUrl)
        } catch CocoaError.fileNoSuchFile {
            return
        } catch {
            Diagnostic.warning("Unable to remove \(fileUrl.path(percentEncoded: false)): \(error)")
        }
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
