// swift-tools-version:5.9
import PackageDescription

// 纯逻辑包：仅依赖 Foundation，可在 Linux（GitHub Actions）上跑单元测试（PRD §8.3）
let package = Package(
    name: "Core",
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    targets: [
        .target(name: "Core"),
        .testTarget(name: "CoreTests", dependencies: ["Core"])
    ]
)
