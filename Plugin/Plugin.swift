import Foundation
import PackagePlugin

@main
struct Plugin: BuildToolPlugin {
    let targetDirectoryName = "Box"
    let toolName = "SecureBoxExecutable"

    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let module = target.sourceModule else {
            throw PluginError.sourceModuleUnavailable(target.name)
        }

        let diagnostics = PluginDiagnostics(
            targetName: target.name,
            targetDirectoryName: targetDirectoryName
        )
        let scan = try scan(module: module, diagnostics: diagnostics)

        diagnostics.discovered(scan: scan, root: module.directoryURL)
        diagnostics.escaping(candidates: scan.candidates, root: module.directoryURL)
        diagnostics.dependencies(of: target.dependencies, severity: .error)

        return try process(
            candidates: scan.candidates,
            at: context.pluginWorkDirectoryURL,
            using: context.tool(named: toolName),
            diagnostics: diagnostics
        )
    }
}

// MARK: - shared
extension Plugin {
    func process(candidates: [URL], at workDirectory: URL, using executable: PackagePlugin.PluginContext.Tool, diagnostics: PluginDiagnostics) throws -> [Command] {
        let paths = PluginPaths(root: workDirectory)
        let inputs = candidates.sorted { $0.absoluteString < $1.absoluteString }
        let resources = inputs.map { candidate in
            PluginTask.Resource(
                input: candidate,
                output: paths.output(
                    name: candidate.deletingPathExtension().lastPathComponent
                )
            )
        }

        diagnostics.collisions(resources: resources)

        let task = PluginTask(
            root: paths.directories.root,
            code: paths.files.code,
            box: paths.directories.box,
            resources: resources
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let encoded = try encoder.encode(task)
        try encoded.write(to: paths.files.task)

        return [
            .buildCommand(
                displayName: "Executing an encryption task at: \(paths.files.task)",
                executable: executable.url,
                arguments: [
                    paths.files.task.path(percentEncoded: false)
                ],
                inputFiles: inputs,
                outputFiles: [paths.files.code] + resources.map(\.output)
            )
        ]
    }
}

// MARK: - private
private extension Plugin {
    func scan(module: any SourceModuleTarget, diagnostics: PluginDiagnostics) throws -> PluginScan {
        let attached = Dictionary(
            module.sourceFiles.map { ($0.url.attachmentKey, $0.type) },
            uniquingKeysWith: { first, _ in first }
        )

        let enumerator = FileManager.default.enumerator(
            at: module.directoryURL,
            includingPropertiesForKeys: [
                .isDirectoryKey
            ],
            options: [
                .skipsHiddenFiles,
                .skipsPackageDescendants
            ]
        )

        guard let enumerator else {
            throw PluginError.directoryContentUnavailable(module.directoryURL)
        }

        var candidates: [URL] = []
        var directories: Set<URL> = []

        for element in enumerator {
            guard let url = (element as? URL)?.standardizedFileURL else {
                throw PluginError.directoryContentUnavailable(module.directoryURL)
            }

            let isBox = url.lastPathComponent == targetDirectoryName
            let isBoxed = url.deletingLastPathComponent().lastPathComponent == targetDirectoryName

            guard isBox || isBoxed else { continue }
            guard let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
                throw PluginError.directoryContentUnavailable(url)
            }
            guard !isDirectory else {
                if isBox {
                    directories.insert(url)

                    if let type = attached[url.attachmentKey] {
                        diagnostics.attached(directory: url, type: type)
                    }
                }

                continue
            }
            guard isBoxed else { continue }

            directories.insert(url.deletingLastPathComponent())

            if let type = attached[url.attachmentKey] {
                diagnostics.attached(file: url, type: type)
            } else {
                candidates.append(url)
            }
        }

        return .init(candidates: candidates, directories: directories)
    }
}
