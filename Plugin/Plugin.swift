import Foundation
import PackagePlugin
import XcodeProjectPlugin

@main
struct Plugin: BuildToolPlugin, XcodeBuildToolPlugin {
    let targetDirectoryName = "Box"
    let toolName = "SecureBoxExecutable"
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        enum BuildToolPluginError: Error {
            case sourceModuleUnavailable
            case directoryContentUnavailable
        }
        
        guard let module = target.sourceModule else {
            throw BuildToolPluginError.sourceModuleUnavailable
        }
        
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

        guard let enumerator = enumerator else {
            throw BuildToolPluginError.directoryContentUnavailable
        }
        
        let attached = Set(module.sourceFiles.map(\.url))
        let candidates: [URL] = try enumerator.compactMap { element in
            guard let url = element as? URL else { throw BuildToolPluginError.directoryContentUnavailable }
            guard !attached.contains(url) else { return nil }
            guard let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
                throw BuildToolPluginError.directoryContentUnavailable
            }
            guard !isDirectory else { return nil }
            guard url.deletingLastPathComponent().lastPathComponent == targetDirectoryName else { return nil }
            
            return url
        }
        
        return try process(
            candidates: candidates,
            in: context
        )
    }
    
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let attached = Set(target.inputFiles.map(\.url))
        let candidates: [URL] = context.xcodeProject.filePaths.compactMap { path in
            let url = URL(filePath: path.string)
            
            guard !attached.contains(url) else { return nil }
            guard url.deletingLastPathComponent().lastPathComponent == targetDirectoryName else { return nil }
            
            return url
        }

        return try process(
            candidates: candidates,
            in: context
        )
    }
}

// MARK: - private
private extension Plugin {
    func process(candidates: [URL], in context: PluginContext) throws -> [Command] {
        return try process(
            candidates: candidates,
            at: context.pluginWorkDirectoryURL,
            using: context.tool(named: toolName)
        )
    }
    
    func process(candidates: [URL], in context: XcodePluginContext) throws -> [Command] {
        return try process(
            candidates: candidates,
            at: context.pluginWorkDirectoryURL,
            using: context.tool(named: toolName)
        )
    }
    
    func process(candidates: [URL], at workDirectory: URL, using executable: PackagePlugin.PluginContext.Tool) throws -> [Command] {
        let paths = PluginPaths(root: workDirectory)
        let resources = candidates.map { candidate in
            PluginTask.Resource(
                input: candidate,
                output: paths.output(
                    name: candidate.deletingPathExtension().lastPathComponent
                )
            )
        }
        
        let task = PluginTask(
            root: paths.directories.root,
            code: paths.files.code,
            box: paths.directories.box,
            resources: resources
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let encoded = try encoder.encode(task)
        try encoded.write(to: paths.files.task)
        
        return [
            .buildCommand(
                displayName: "Executing an encryption task at: \(paths.files.task)",
                executable: executable.url,
                arguments: [
                    paths.files.task.path(percentEncoded: false)
                ],
                inputFiles: candidates,
                outputFiles: [paths.files.code] + resources.map(\.output)
            )
        ]
    }
}
