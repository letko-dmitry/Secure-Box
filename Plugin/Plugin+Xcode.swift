//
//  Plugin+Xcode.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

#if canImport(XcodeProjectPlugin)
import Foundation
import PackagePlugin
import XcodeProjectPlugin

// MARK: - XcodeBuildToolPlugin
extension Plugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let diagnostics = PluginDiagnostics(
            targetName: target.displayName,
            targetDirectoryName: targetDirectoryName
        )
        let scan = scan(project: context.xcodeProject, target: target, diagnostics: diagnostics)

        diagnostics.discovered(scan: scan, root: context.xcodeProject.directoryURL)
        diagnostics.escaping(candidates: scan.candidates, root: context.xcodeProject.directoryURL)
        diagnostics.dependencies(of: target.dependencies, severity: .warning)

        return try process(
            candidates: scan.candidates,
            at: context.pluginWorkDirectoryURL,
            using: context.tool(named: toolName),
            diagnostics: diagnostics
        )
    }
}

// MARK: - private
private extension Plugin {
    func scan(project: XcodeProject, target: XcodeTarget, diagnostics: PluginDiagnostics) -> PluginScan {
        let attached = Dictionary(
            target.inputFiles.map { ($0.url.attachmentKey, $0.type) },
            uniquingKeysWith: { first, _ in first }
        )
        let owners = owners(in: project, excluding: target)
        let fileManager = FileManager.default

        var candidates: [URL] = []
        var directories: Set<URL> = []
        var referenced: [URL: Set<String>] = [:]

        for path in project.filePaths {
            let url = URL(filePath: path.string).standardizedFileURL
            let isBox = url.lastPathComponent == targetDirectoryName
            let isBoxed = url.deletingLastPathComponent().lastPathComponent == targetDirectoryName

            guard isBox || isBoxed else { continue }

            var isDirectory: ObjCBool = false

            guard fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
                if isBoxed {
                    diagnostics.dangling(file: url)
                }

                continue
            }
            guard !isDirectory.boolValue else {
                if isBox {
                    directories.insert(url)

                    if let type = attached[url.attachmentKey] {
                        diagnostics.attached(directory: url, type: type)
                    }
                }

                continue
            }
            guard isBoxed else { continue }

            let directory = url.deletingLastPathComponent()

            directories.insert(directory)
            referenced[directory, default: []].insert(url.lastPathComponent)

            if let type = attached[url.attachmentKey] {
                diagnostics.attached(file: url, type: type)

                continue
            }

            if let names = owners[url.attachmentKey] {
                diagnostics.foreign(file: url, targets: names)
            }

            candidates.append(url)
        }

        diagnostics.orphans(in: directories, referenced: referenced)

        return .init(candidates: candidates, directories: directories)
    }

    /** Maps every file the project knows about to the targets, other than the one being built, that ship it. */
    func owners(in project: XcodeProject, excluding target: XcodeTarget) -> [String: [String]] {
        var owners: [String: [String]] = [:]

        project.targets
            .filter { $0.id != target.id }
            .forEach { other in
                other.inputFiles.forEach { file in
                    owners[file.url.attachmentKey, default: []].append(other.displayName)
                }
            }

        return owners
    }
}
#endif
