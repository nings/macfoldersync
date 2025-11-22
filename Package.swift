// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FolderSyncPro",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "FolderSyncProCore",
            targets: ["FolderSyncProCore"]
        ),
    ],
    dependencies: [
        // 添加任何外部依赖
    ],
    targets: [
        .target(
            name: "FolderSyncProCore",
            dependencies: [],
            path: "FolderSyncPro/FolderSyncPro",
            exclude: [
                "App",  // 排除 App 入口（需要完整的 Xcode 项目）
                "Resources",  // 排除资源文件
            ],
            sources: [
                "Models",
                "Services",
                "Utils",
                "Views"
            ]
        ),
        .testTarget(
            name: "FolderSyncProCoreTests",
            dependencies: ["FolderSyncProCore"],
            path: "FolderSyncPro/FolderSyncProTests"
        ),
    ]
)
