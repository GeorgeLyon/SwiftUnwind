// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "SwiftUnwind",
  platforms: [
    .macOS(.v11)
  ],
  targets: [
    .target(name: "CLibUnwind"),
    .target(
      name: "SwiftUnwind",
      dependencies: ["CLibUnwind"]),
    .target(
      name: "Sample",
      dependencies: ["SwiftUnwind"]),
  ]
)
