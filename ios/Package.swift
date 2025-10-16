// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RustMemeApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "RustMemeApp",
            targets: ["RustMemeApp"])
    ],
    dependencies: [
        // WalletConnect for Web3 wallet integration
        .package(url: "https://github.com/WalletConnect/WalletConnectSwiftV2", from: "1.9.0"),
        // Web3.swift for Ethereum interactions
        .package(url: "https://github.com/argentlabs/web3.swift", from: "1.6.0"),
    ],
    targets: [
        .target(
            name: "RustMemeApp",
            dependencies: [
                .product(name: "WalletConnectSwiftV2", package: "WalletConnectSwiftV2"),
                .product(name: "web3.swift", package: "web3.swift"),
            ]
        )
    ]
)
