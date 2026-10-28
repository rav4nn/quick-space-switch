// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickSpaceSwitch",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "QuickSpaceSwitch", targets: ["QuickSpaceSwitch"]),
        .executable(name: "QSSCli", targets: ["QSSCli"])
    ],
    targets: [
        .target(
            name: "ISS",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "QuickSpaceSwitch",
            dependencies: ["ISS"]
        ),
        .executableTarget(
            name: "QSSCli",
            dependencies: ["ISS"],
            path: "Sources/QSSCli"
        ),
        .testTarget(
            name: "ISSTests",
            dependencies: ["ISS", "QuickSpaceSwitch"]
        )
    ]
)
