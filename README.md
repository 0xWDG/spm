# spm

spm is a Swift Package for ...

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2Fspm%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/0xWDG/spm)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2Fspm%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/0xWDG/spm)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/0xWDG/spm)

## Requirements

- Swift 5.8+ (Xcode 15+)
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+

## Installation (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/0xWDG/spm.git", branch: "main"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "spm", package: "spm"),
    ]),
]
```

## Installation (Xcode)

1. In Xcode, open your project and navigate to **File** → **Swift Packages** → **Add Package Dependency...**
2. Paste the repository URL (`https://github.com/0xWDG/spm`) and click **Next**.
3. Click **Finish**.

## Usage

```swift
import SwiftUI
import spm

struct ContentView: View {
    var body: some View {
        VStack {
            /// ...
        }
        .padding()
    }
}
```

## Contact

🦋 [@0xWDG](https://bsky.app/profile/0xWDG.bsky.social)
🐘 [mastodon.social/@0xWDG](https://mastodon.social/@0xWDG)
🐦 [@0xWDG](https://x.com/0xWDG)
🧵 [@0xWDG](https://www.threads.net/@0xWDG)
🌐 [wesleydegroot.nl](https://wesleydegroot.nl)
🤖 [Discord](https://discordapp.com/users/918438083861573692)

Interested learning more about Swift? [Check out my blog](https://wesleydegroot.nl/blog/).