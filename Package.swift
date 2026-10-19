// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "BskyBotSwift",
  platforms: [.macOS(.v26)],
  products: [
    .executable(name: "bot", targets: ["BskyBotSwift"])
  ],
  dependencies: [
    .package(url: "https://github.com/nnabeyang/swift-atproto.git", from: "0.44.5")
  ],
  targets: [
    .executableTarget(
      name: "BskyBotSwift",
      dependencies: [
        .product(name: "SwiftAtproto", package: "swift-atproto")
      ],
      swiftSettings: [
        .enableUpcomingFeature("ApproachableConcurrency")
      ],
    ),
    .testTarget(
      name: "BskyBotSwiftTests",
      dependencies: ["BskyBotSwift"],
      swiftSettings: [
        .enableUpcomingFeature("ApproachableConcurrency")
      ],
    ),
  ]
)
