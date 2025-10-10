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
        
        let attached = Set(module.sourceFiles.map { $0.path.string })
        let candidates = try enumerator.filter { element in
            guard let url = element as? URL else { throw BuildToolPluginError.directoryContentUnavailable }
            guard !attached.contains(url.path()) else { return false }
            guard let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
                throw BuildToolPluginError.directoryContentUnavailable
            }
            guard !isDirectory else { return false }
            guard url.deletingLastPathComponent().lastPathComponent == targetDirectoryName else { return false }
            
            return true
        }
        
        return try process(
            candidates: candidates.map { PathList.Element(($0 as! URL).path()) },
            in: context
        )
    }
    
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let attached = Set(target.inputFiles.map { $0.path })
        let candidates = context.xcodeProject.filePaths.filter { path in
            guard !attached.contains(path) else { return false }
            guard path.removingLastComponent().lastComponent == targetDirectoryName else { return false }
            
            return true
        }
        
        return try process(
            candidates: Array(candidates),
            in: context
        )
    }
}

// MARK: - private
private extension Plugin {
    func process(candidates: [PathList.Element], in context: PluginContext) throws -> [Command] {
        return try process(
            candidates: candidates,
            at: context.pluginWorkDirectory,
            using: context.tool(named: toolName)
        )
    }
    
    func process(candidates: [PathList.Element], in context: XcodePluginContext) throws -> [Command] {
        return try process(
            candidates: candidates,
            at: context.pluginWorkDirectory,
            using: context.tool(named: toolName)
        )
    }
    
    func process(candidates: [PathList.Element], at workDirectory: Path, using executable: PackagePlugin.PluginContext.Tool) throws -> [Command] {
        let paths = PluginPaths(root: workDirectory)
        let resources = candidates.map { candidate in
            PluginTask.Resource(
                input: candidate,
                output: paths.output(name: candidate.stem)
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
        try encoded.write(to: .init(filePath: paths.files.task.string, directoryHint: .notDirectory))
        
        return [
            .buildCommand(
                displayName: "Executing an encryption task at: \(paths.files.task)",
                executable: executable.path,
                arguments: [paths.files.task],
                inputFiles: candidates,
                outputFiles: [paths.files.code] + resources.map { $0.output }
            )
        ]
    }
}
