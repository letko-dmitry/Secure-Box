//
//  PluginDiagnostics.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 13/08/2026.
//

import Foundation
import PackagePlugin

struct PluginDiagnostics {
    let targetName: String
    let targetDirectoryName: String
}

// MARK: - candidates
extension PluginDiagnostics {
    /** Reports a file that sits in a box directory but is already owned by the target being built. */
    func attached(file fileUrl: URL, type: FileType) {
        let name = fileUrl.lastPathComponent
        let hint = "Exclude '\(targetDirectoryName)' from '\(targetName)' so Secure Box can seal it."

        switch type {
        case .resource:
            Diagnostics.error(
                "'\(name)' is declared as a resource of '\(targetName)' and will be copied into the bundle unencrypted. \(hint)",
                file: fileUrl.path(percentEncoded: false)
            )

        default:
            Diagnostics.warning(
                "'\(name)' is a source of '\(targetName)' and will not be sealed into Secure Box. \(hint)",
                file: fileUrl.path(percentEncoded: false)
            )
        }
    }

    /** Reports a whole box directory that the target being built ships as one resource. */
    func attached(directory directoryUrl: URL, type: FileType) {
        guard type == .resource else { return }

        Diagnostics.error(
            "'\(directoryUrl.lastPathComponent)' is declared as a resource of '\(targetName)' and all of its content will be copied into the bundle unencrypted. Exclude it from '\(targetName)' so Secure Box can seal it.",
            file: directoryUrl.path(percentEncoded: false)
        )
    }

    /** Reports two or more files that would be sealed into the very same output. */
    func collisions(resources: [PluginTask.Resource]) {
        Dictionary(grouping: resources, by: \.output)
            .filter { $0.value.count > 1 }
            .sorted { $0.key.absoluteString < $1.key.absoluteString }
            .forEach { output, colliding in
                let inputs = colliding
                    .map { "'\($0.input.path(percentEncoded: false))'" }
                    .sorted()
                    .joined(separator: ", ")

                Diagnostics.error("\(inputs) are all sealed into '\(output.lastPathComponent)' and would overwrite each other. Give them distinct file names.")
            }
    }

    /** Reports a symbolic link that leaves the package or the project, making the build depend on the machine it runs on. */
    func escaping(candidates: [URL], root: URL) {
        let prefix = root.resolvingSymlinksInPath().standardizedFileURL.path(percentEncoded: false).appendingTrailingSlash

        candidates.forEach { candidate in
            let isSymbolicLink = (try? candidate.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink ?? false

            guard isSymbolicLink else { return }

            let resolved = candidate.resolvingSymlinksInPath().standardizedFileURL.path(percentEncoded: false)

            guard !resolved.hasPrefix(prefix) else { return }

            Diagnostics.warning(
                "'\(candidate.lastPathComponent)' is a symbolic link to \(resolved), which is outside of \(prefix). The sealed content depends on the machine running the build.",
                file: candidate.path(percentEncoded: false)
            )
        }
    }

    /** Tells apart a misnamed directory from a directory that simply holds nothing. */
    func discovered(scan: PluginScan, root: URL) {
        guard !scan.directories.isEmpty else {
            return Diagnostics.remark("No '\(targetDirectoryName)' directory found under \(root.path(percentEncoded: false)); '\(targetName)' gets an empty Secure Box.")
        }

        guard scan.candidates.isEmpty else { return }

        Diagnostics.remark("Found \(scan.directories.count) '\(targetDirectoryName)' director\(scan.directories.count == 1 ? "y" : "ies") holding nothing to seal; '\(targetName)' gets an empty Secure Box.")
    }
}

// MARK: - dependencies
extension PluginDiagnostics {
    /** The modules the generated code imports and therefore the target has to be able to see. */
    static let requiredModules: Set<String> = [
        "SecureBoxTypes",
        "ObfuscateMacro"
    ]

    func dependencies(of dependencies: [TargetDependency], severity: Diagnostics.Severity) {
        var visited: Set<String> = []
        var reachable: Set<String> = []

        Self.collect(dependencies, visited: &visited, into: &reachable)

        report(reachable: reachable, severity: severity)
    }

    func report(reachable: Set<String>, severity: Diagnostics.Severity) {
        Self.requiredModules.subtracting(reachable).sorted().forEach { module in
            Diagnostics.emit(severity, "The generated Secure Box code imports '\(module)', which '\(targetName)' does not depend on. Add it to the dependencies of '\(targetName)'.")
        }
    }

    static func collect(_ dependencies: [TargetDependency], visited: inout Set<String>, into reachable: inout Set<String>) {
        dependencies.forEach { dependency in
            switch dependency {
            case let .target(target):
                collect(target, visited: &visited, into: &reachable)

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

    static func collect(_ target: any Target, visited: inout Set<String>, into reachable: inout Set<String>) {
        reachable.insert(target.name)

        guard visited.insert(target.id).inserted else { return }

        collect(target.dependencies, visited: &visited, into: &reachable)
    }
}

// MARK: - String
private extension String {
    var appendingTrailingSlash: String {
        hasSuffix("/") ? self : "\(self)/"
    }
}
