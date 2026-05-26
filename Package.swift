// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "trmnl-apple-reminders-sender",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "TRMNLAppleRemindersCore"
        ),
        .executableTarget(
            name: "trmnl-apple-reminders-sender",
            dependencies: ["TRMNLAppleRemindersCore"]
        ),
        .testTarget(
            name: "trmnl-apple-reminders-senderTests",
            dependencies: ["TRMNLAppleRemindersCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
