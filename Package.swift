// swift-tools-version: 6.2
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
                "SecureBoxTypes",
                "SecureBoxOpen"
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
                .target(name: "SecureBoxTypes"),
                .target(name: "SecureBoxSeal")
            ],
            path: "Executable",
            swiftSettings: .default,
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .target(
            name: "SecureBoxTypes",
            path: "Resources/Types",
            swiftSettings: .default,
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .target(
            name: "SecureBoxOpen",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .target(name: "SecureBoxTypes")
            ],
            path: "Resources/Open",
            swiftSettings: .default,
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .target(
            name: "SecureBoxSeal",
            dependencies: [
                .target(name: "SecureBoxTypes")
            ],
            path: "Resources/Seal",
            swiftSettings: .default,
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
                .target(name: "SecureBoxTypes"),
                .target(name: "SecureBoxOpen"),
            ],
            path: "Playground",
            exclude: [
                "Box"
            ],
            swiftSettings: .default,
            plugins: [
                .plugin(name: "SecureBoxPlugin")
            ]
        )
    ]
)

// MARK: - SwiftSetting
private extension SwiftSetting {
    static let disableReflectionMetadata = SwiftSetting.unsafeFlags(["-Xfrontend", "-disable-reflection-metadata"], .when(configuration: .release))
    static let approachableConcurrency = SwiftSetting.enableUpcomingFeature("ApproachableConcurrency")
    static let internalImportsByDefault = SwiftSetting.enableUpcomingFeature("InternalImportsByDefault")
    static let existentialAny = SwiftSetting.enableUpcomingFeature("ExistentialAny")
    static let memberImportVisibility = SwiftSetting.enableUpcomingFeature("MemberImportVisibility")
}

// MARK: - SwiftSetting
private extension Array<SwiftSetting> {
    static let `default`: Self = [
        .disableReflectionMetadata,
        .internalImportsByDefault,
        .approachableConcurrency,
        .existentialAny,
        .memberImportVisibility
    ]
}
