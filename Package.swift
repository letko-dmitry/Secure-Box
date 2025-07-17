// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Secure-Box",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SecureBoxResources",
            targets: [
                "SecureBoxResources"
            ]
        ),
        .plugin(
            name: "SecureBoxPlugin",
            targets:  [
                "SecureBoxPlugin"
            ]
        )
    ],
    dependencies: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.53.0"),
        .package(url: "git@github.com:apple/swift-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SecureBoxExecutable",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .target(name: "SecureBoxResources")
            ],
            path: "Executable",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .target(
            name: "SecureBoxResources",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Resources",
            swiftSettings: [
                .disableReflectionMetadata
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .plugin(
            name: "SecureBoxPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SecureBoxExecutable")
            ],
            path: "Plugin"
        ),
        .executableTarget(
            name: "SecureBoxPlayground",
            dependencies: [
                .target(name: "SecureBoxResources")
            ],
            path: "Playground",
            exclude: [
                "Box"
            ],
            plugins: [
                .plugin(name: "SecureBoxPlugin")
            ]
        )
    ]
)

// MARK: - SwiftSetting
private extension SwiftSetting {
    static let disableReflectionMetadata = SwiftSetting.unsafeFlags(["-Xfrontend", "-disable-reflection-metadata"], .when(configuration: .release))
}
