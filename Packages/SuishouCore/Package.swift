// swift-tools-version:5.9
import PackageDescription

// 纯逻辑包：仅依赖 Foundation，可在 Linux（GitHub Actions）上跑单元测试（PRD §8.3）
// 注意：模块名避开 "Core"，防止与 SDK 内同名模块冲突
let package = Package(
    name: "SuishouCore",
    products: [
        .library(name: "SuishouCore", targets: ["SuishouCore"])
    ],
    targets: [
        .target(name: "SuishouCore"),
        .testTarget(name: "SuishouCoreTests", dependencies: ["SuishouCore"])
    ]
)
