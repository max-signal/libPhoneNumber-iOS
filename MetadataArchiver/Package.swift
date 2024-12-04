// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MetadataArchiver",
    platforms: [.macOS(.v15)],
    targets: [.executableTarget(name: "MetadataArchiver")]
)
