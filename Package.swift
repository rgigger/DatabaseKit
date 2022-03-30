// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DatabaseKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DatabaseKit",
            targets: ["DatabaseKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rgigger/SwiftLMDB", revision: "2.2.0")
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DatabaseKit",
            dependencies: ["SwiftLMDB"]
        ),
        .testTarget(
            name: "database-kitTests",
            dependencies: ["DatabaseKit"],
            resources: [.process("Resources/test.jpg")]
        ),
    ]
)
