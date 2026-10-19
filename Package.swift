// swift-tools-version:5.3

import PackageDescription

/// Debug-only flags for AppViewServer (iOS/tvOS simulator/device).
private let debugAppViewCXXSettings: [CXXSetting] = [
    .define("SHOULD_COMPILE_APPVIEW_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_APPVIEW_SERVER_ENABLED", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugAppViewSwiftSettings: [SwiftSetting] = [
    .define("SHOULD_COMPILE_APPVIEW_SERVER", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_APPVIEW_SERVER_ENABLED", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("APPVIEW_SERVER_MCP", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugAppViewServerCSettings: [CSetting] = [
    .define("SHOULD_COMPILE_APPVIEW_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

/// AppViewShared pod parity: server/shared compile flags on all platforms.
private let appviewSharedSwiftSettings: [SwiftSetting] = [
    .define("SHOULD_COMPILE_APPVIEW_SERVER"),
]

private let appviewSharedCSettings: [CSetting] = [
    .define("SHOULD_COMPILE_APPVIEW_SERVER", to: "1"),
]

/// Files compiled into AppViewShared (also excluded from AppViewServer — SPM allows one target per source file).
private let appviewSharedOnlyExcludesFromServer: [String] = [
    "AppViewServerCore/AppViewDashboardBlueprint.swift",
    "AppViewServerCore/AppViewAttributeGetter.swift",
    "AppViewServerCategories/CALayer+AppView.swift",
    "AppViewServerCategories/NSSet+AppView.swift",
    "AppViewServerCategories/AppViewAutoLayoutConstraint.swift",
]

/// AppViewServer-only sources (server runtime; shared wire/models live in AppViewShared).
private let appviewServerExclusiveSources: [String] = [
    "AppViewServerShared/AVS_ObjectRegistry.swift",
    "AppViewServerCategories",
    "AppViewServerCore",
    "AppViewServerConnection",
    "AppViewServerConnectionBootstrap",
    "AppViewServerMCP",
    "AppViewServerOthers",
    "AppViewServer",
]

private let appviewServerExcludes: [String] = [
    "AppViewServerShared/AppViewDefines.swift",
    "AppViewServerCore/AppViewAttrIdentifiers.swift",
    "AppViewServerOthers/AppViewObjCExceptionCatch.m",
    "AppViewServerCategories/README.md",
    "AppViewServerCore/README.md",
    "AppViewServerPeertalk/README.md",
    "AppViewServerMCP/README.md",
    "AppViewServerOthers/README.md",
] + appviewSharedOnlyExcludesFromServer

/// Unified AppViewShared target — mirrors AppViewShared.podspec.
private let appviewSharedSources: [String] = [
    "AppViewServerBase/AppViewIvarTrace.swift",
    "AppViewServerShared",
    "AppViewServerCore/AppViewDashboardBlueprint.swift",
    "AppViewServerCore/AppViewAttributeGetter.swift",
    "AppViewServerPeertalk",
    "AppViewServerCategories/CALayer+AppView.swift",
    "AppViewServerCategories/NSSet+AppView.swift",
    "AppViewServerCategories/AppViewAutoLayoutConstraint.swift",
]

private let appviewSharedExcludes: [String] = [
    "AppViewServerShared/AppViewDefines.swift",
    "AppViewServerShared/AVS_ObjectRegistry.swift",
    "AppViewServerShared/MacAppViewClientCompatibility.md",
    "AppViewServerPeertalk/README.md",
]

let package = Package(
    name: "AppViewServer",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "AppViewServer",
            targets: ["AppViewServer"]
        ),
        .library(
            name: "AppViewShared",
            targets: ["AppViewShared"]
        ),
    ],
    targets: [
        /// Single ObjC translation unit — SPM 5.3 cannot mix .m + Swift in one target.
        .target(
            name: "AppViewServerObjCBridge",
            dependencies: [],
            path: "Sources/AppViewServerOthers",
            sources: ["AppViewObjCExceptionCatch.m"],
            publicHeadersPath: ".",
            cSettings: debugAppViewServerCSettings
        ),

        .target(
            name: "AppViewShared",
            dependencies: ["AppViewServerObjCBridge"],
            path: "Sources",
            exclude: appviewSharedExcludes,
            sources: appviewSharedSources,
            publicHeadersPath: "AppViewServerBase",
            cSettings: appviewSharedCSettings,
            swiftSettings: appviewSharedSwiftSettings
        ),

        .target(
            name: "AppViewServer",
            dependencies: ["AppViewServerObjCBridge", "AppViewShared"],
            path: "Sources",
            exclude: appviewServerExcludes,
            sources: appviewServerExclusiveSources,
            cSettings: debugAppViewServerCSettings,
            cxxSettings: debugAppViewCXXSettings,
            swiftSettings: debugAppViewSwiftSettings
        ),

        .testTarget(
            name: "AppViewServerSharedTests",
            dependencies: ["AppViewServer"],
            path: "Tests/AppViewServerSharedTests"
        ),

        .testTarget(
            name: "AppViewServerConnectionTests",
            dependencies: ["AppViewServer"],
            path: "Tests/AppViewServerConnectionTests",
            swiftSettings: debugAppViewSwiftSettings
        ),
    ]
)
