// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "RiveRuntime",
    platforms: [.iOS("14.0"), .visionOS("1.0"), .tvOS("16.0"), .macOS("13.1")],
    products: [
        .library(
            name: "RiveRuntime",
            targets: ["RiveRuntime"])],
    targets: [
        .binaryTarget(
            name: "RiveRuntime",
            url: "https://github.com/artem-shvetsov/rive-ios/releases/download/6.8.0/RiveRuntime.xcframework.zip",
            checksum: "b2bac289dbb8f52c03b91c4ee4ba190068c24bc34cb74c7daf0c35f93d3e722b"
        )
    ]
)
