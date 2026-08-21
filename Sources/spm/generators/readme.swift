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

public extension SPM {
/// Generates a README.md file from configured or built-in README content.
static func generateReadme(options: OverwriteOptions = OverwriteOptions()) throws {
    _ = try requiredProductName()
    let configuration = try activeConfiguration()
    let readme = renderTemplate(
        try configurationValueContent(
            configuration.readme,
            fileNames: ["README.md"]
        ) ?? defaultReadmeTemplate,
        configuration: configuration
    )

    try writeGeneratedFile(readme, to: projectURL("README.md"), options: options)
    if !options.dryRun {
        printC("Generated README.md", color: CLIColors.green)
    }
}

/// Built-in README template.
static var defaultReadmeTemplate: String {
    let platformBadge = [
        "[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2F",
        "packages%2F{{github}}%2FPACKAGENAME%2Fbadge%3Ftype%3Dplatforms)]",
        "(https://swiftpackageindex.com/{{github}}/PACKAGENAME)"
    ].joined()
    let swiftBadge = [
        "[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2F",
        "packages%2F{{github}}%2FPACKAGENAME%2Fbadge%3Ftype%3Dswift-versions)]",
        "(https://swiftpackageindex.com/{{github}}/PACKAGENAME)"
    ].joined()
    let spmBadge = [
        "[![Swift Package Manager]",
        "(https://img.shields.io/badge/SPM-compatible-brightgreen.svg)]",
        "(https://swift.org/package-manager)"
    ].joined()

    return [
        "# PACKAGENAME",
        "PACKAGENAME is a Swift Package for ...",
        platformBadge,
        swiftBadge,
        spmBadge,
        "![License](https://img.shields.io/github/license/{{github}}/PACKAGENAME)",
        defaultReadmeBody
    ].joined(separator: "\n\n")
}

/// Built-in README body template.
static var defaultReadmeBody: String {
    """
    ## Requirements

    - Swift 6.0+ (Xcode 16+)
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

    1. In Xcode, open your project and navigate to **File > Swift Packages > Add Package Dependency...**
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

    [{{website}}]({{website}})

    Interested learning more about Swift? [Check out my blog]({{website}}/blog/).
    """
}
}
