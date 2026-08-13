//
//  PluginDiagnostics+Xcode.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

#if canImport(XcodeProjectPlugin)
import Foundation
import PackagePlugin
import XcodeProjectPlugin

// MARK: - candidates
extension PluginDiagnostics {
    /** Reports a file that is a member of another target and therefore ships unencrypted with it. */
    func foreign(file fileUrl: URL, targets: [String]) {
        let names = targets.sorted().map { "'\($0)'" }.joined(separator: ", ")

        Diagnostics.warning(
            "'\(fileUrl.lastPathComponent)' is a member of \(names) and will be copied into their bundles unencrypted, even though Secure Box seals it for '\(targetName)'.",
            file: fileUrl.path(percentEncoded: false)
        )
    }

    /** Reports a project reference that no longer resolves to anything on disk. */
    func dangling(file fileUrl: URL) {
        Diagnostics.warning(
            "'\(fileUrl.lastPathComponent)' is referenced by the project but is missing on disk, so it cannot be sealed into Secure Box.",
            file: fileUrl.path(percentEncoded: false)
        )
    }

    /** Reports files that sit in a box directory on disk but that the project knows nothing about. */
    func orphans(in directories: Set<URL>, referenced: [URL: Set<String>]) {
        let fileManager = FileManager.default

        directories.sorted { $0.absoluteString < $1.absoluteString }.forEach { directory in
            let known = referenced[directory] ?? []
            let content = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            content?.forEach { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

                guard !isDirectory, !known.contains(url.lastPathComponent) else { return }

                Diagnostics.warning(
                    "'\(url.lastPathComponent)' is not referenced by the project and will not be sealed into Secure Box. Add it to the project, but not to the build phases of any target.",
                    file: url.path(percentEncoded: false)
                )
            }
        }
    }
}

// MARK: - dependencies
extension PluginDiagnostics {
    func dependencies(of dependencies: [XcodeTargetDependency], severity: Diagnostics.Severity) {
        var visited: Set<String> = []
        var reachable: Set<String> = []

        Self.collect(dependencies, visited: &visited, into: &reachable)

        report(reachable: reachable, severity: severity)
    }

    static func collect(_ dependencies: [XcodeTargetDependency], visited: inout Set<String>, into reachable: inout Set<String>) {
        dependencies.forEach { dependency in
            switch dependency {
            case let .target(target):
                reachable.insert(target.displayName)

                guard visited.insert(target.id).inserted else { return }

                collect(target.dependencies, visited: &visited, into: &reachable)

            case let .product(product):
                reachable.insert(product.name)
                product.targets.forEach { target in
                    collect(target, visited: &visited, into: &reachable)
                }

            @unknown default:
                return
            }
        }
    }
}
#endif
