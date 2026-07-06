//
//  readme.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Generates a README.md file from configured or built-in README content.
public func generateReadme() {
    let configuration = activeConfiguration()
    let defaultReadme = """
# PACKAGENAME

PACKAGENAME is a Swift Package for ...

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F{{github}}%2FPACKAGENAME%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/{{github}}/PACKAGENAME)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F{{github}}%2FPACKAGENAME%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/{{github}}/PACKAGENAME)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/{{github}}/PACKAGENAME)

## Requirements

- Swift 5.8+ (Xcode 15+)
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+

## Installation (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/{{github}}/PACKAGENAME.git", branch: "main"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "PACKAGENAME", package: "PACKAGENAME"),
    ]),
]
```

## Installation (Xcode)

1. In Xcode, open your project and navigate to **File** → **Swift Packages** → **Add Package Dependency...**
2. Paste the repository URL (`https://github.com/{{github}}/PACKAGENAME`) and click **Next**.
3. Click **Finish**.

## Usage

```swift
import SwiftUI
import PACKAGENAME

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

🌐 [{{website}}]({{website}})

Interested learning more about Swift? [Check out my blog]({{website}}/blog/).
"""

    let readme = renderTemplate(
        configurationValueContent(
            configuration.readme,
            fileNames: ["README.md"]
        ) ?? defaultReadme,
        configuration: configuration
    )

    do {
        try readme.write(to: URL(fileURLWithPath: "README.md"), atomically: true, encoding: .utf8)
        printC("Generated README.md", color: CLIColors.green)
    } catch {
        printC("Failed to generate README.md", color: CLIColors.red)
    }
}
