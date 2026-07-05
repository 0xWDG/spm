#!/usr/bin/swift

//
//  spm.swift
//  This script will add a header to all .swift files in the current directory.
//  And can test the package for various platforms.
//
//  Created by Wesley de Groot on 2024-08-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm-template
//  MIT License

// To compile this script to a binary, run:
// swiftc spm -o spm.bin

import Foundation

let fileManager = FileManager.default
var internalProductName: String?
var productName: String {
    get {
        if let productName = internalProductName {
            return productName
        }

        if fileManager.fileExists(atPath: "Package.swift") {
            guard let package = try? String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8),
                  let productName = package
                .components(separatedBy: .newlines)
                .first(where: { $0.contains("name:") })?
                .components(separatedBy: .whitespaces)
                .last?
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: ",", with: "") else {
                printC("Could not find product name in Package.swift", color: CLIColors.red)
                exit(2)
            }

            return productName
        } else {
            printC("Package.swift not found, please provide package name", color: CLIColors.red)
            return ""
        }
    }
    set {
        internalProductName = newValue
    }
}

struct CLIColors {
    static let red = "\u{001B}[0;31m"
    static let green = "\u{001B}[0;32m"
    static let yellow = "\u{001B}[0;33m"
    static let orange = "\u{001B}[0;38;5;208m"
    static let blue = "\u{001B}[0;34m"
    static let magenta = "\u{001B}[0;35m"
    static let cyan = "\u{001B}[0;36m"
    static let white = "\u{001B}[0;37m"
    static let reset = "\u{001B}[0;0m"
    static let clear = "\u{001B}[0;0m"
    static let bold = "\u{001B}[1m"
    static let underline = "\u{001B}[4m"
}

func printUsage() {
    let executable = CommandLine.arguments[0].components(separatedBy: "/").last ?? "spm"

    print("spm - Swift Package Manager Manager (v0.0.2)\n")
    print("Usage: \(executable) <command>\n")

    print("Commands:")
    print(" Create <package name> - Create a package in current directory")
    print(" header - Update the header for all .swift files in the current directory")
    print(" readme - Generate a README.md file for the package (overwrites existing file)")
    print(" licence - Generate a LICENCE.md file for the package (overwrites existing file)")
    print(" build - Build the package for all platforms")
    print(" test [swift-test-options] - Test the Swift package project")
    print(" --test [swift-test-options] - Test the Swift package project")
    print(" install <package url|owner/repo|repo> - Install a Swift package into the Xcode project in the current directory")
}

func printC(_ text: String, terminator: String = "\n", color: String = CLIColors.reset) {
    if terminator == "\n" {
        print("\(color)\(text)                        \(CLIColors.reset)")
    } else {
        print("\(color)\(text)\(CLIColors.reset)", terminator: terminator)
        fflush(stdout)
    }
}

if CommandLine.argc < 2 {
    printUsage()
    exit(1)
}

if CommandLine.arguments[1] == "create" && CommandLine.argc < 3 {
    print("Usage: \(CommandLine.arguments[0]) create <package name>")
    exit(1)
}

if ["install", "package-install", "xcode-install"].contains(CommandLine.arguments[1]) {
    guard CommandLine.argc == 3 else {
        print("Usage: \(CommandLine.arguments[0]) \(CommandLine.arguments[1]) <swift-package-url|owner/repo|repo>")
        exit(1)
    }

    do {
        try installSwiftPackageInXcodeProject(packageURL: CommandLine.arguments[2])
        exit(0)
    } catch {
        printC("Error: \(error)", color: CLIColors.red)
        exit(1)
    }
}

if CommandLine.arguments[1] == "create" && CommandLine.argc == 3 {
    productName = CommandLine.arguments[2]

    if !fileManager.fileExists(atPath: "Package.swift") {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["swift", "package", "init", "--name", productName]
        process.launch()
        process.waitUntilExit()
    }

    /// Change the first line of the Package.swift file
    let package = try String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8)
    let newPackage = package
        .components(separatedBy: .newlines)
        .enumerated()
        .map { index, line in
            if index == 0 {
                return "// swift-tools-version: 5.8.0"
            } else {
                return line
            }
        }
        .joined(separator: "\n")
    try? newPackage.write(to: URL(fileURLWithPath: "Package.swift"), atomically: true, encoding: .utf8)
    printC("Downgraded swift-tools-version to 5.8.0", color: CLIColors.green)

    let spi = """
version: 1
builder:
  configs:
    - documentation_targets: [\(productName)]
"""
    try spi.write(to: URL(fileURLWithPath: ".spi.yml"), atomically: true, encoding: .utf8)

    header()

    if !fileManager.fileExists(atPath: "README.md") {
        generateReadme()
    }

    if !fileManager.fileExists(atPath: "LICENCE.md") {
        generateMITLicense()
    }

    if !fileManager.fileExists(atPath: ".editorconfig") {
        generateEditorConfig()
    }

    if !fileManager.fileExists(atPath: ".gitignore") {
        generateGitIgnore()
    }

    if !fileManager.fileExists(atPath: ".swiftlint.yml") {
        generateSwiftLint()
    }
}

if CommandLine.arguments[1] == "header" {
    header()
}

if CommandLine.arguments[1] == "readme" {
    generateReadme()
}

if CommandLine.arguments[1] == "editorconfig" {
    generateEditorConfig()
}

if CommandLine.arguments[1] == "licence" {
    generateMITLicense()
}

if CommandLine.arguments[1] == "gitignore" {
    generateGitIgnore()
}

if CommandLine.arguments[1] == "swiftlint" {
    generateSwiftLint()
}

if CommandLine.arguments[1] == "build" {
    if !fileManager.fileExists(atPath: "Package.swift") {
        printC("Package.swift not found", color: CLIColors.red)
        exit(2)
    }

    // Find platforms in Package.swift
    let package = try String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8)
    var platforms: [String] = []
    var fails = 0

    if package.contains(".iOS") {
        platforms.append("iOS")
    }

    if package.contains(".macOS") {
        platforms.append("macOS")
    }

    if package.contains(".watchOS") {
        platforms.append("watchOS")
    }

    if package.contains(".visionOS") {
        platforms.append("xrOS")
    }

    if package.contains(".tvOS") {
        platforms.append("tvOS")
    }

    if package.contains(".maccatalyst") {
        platforms.append("MacCatalyst")
    }

    if package.contains(".driverkit") {
        printC("DriverKit is not supported, skipped", color: CLIColors.orange)
        // platforms.append("DriverKit")
    }

    if package.contains(".linux") {
        printC("Linux is not supported, skipped", color: CLIColors.orange)
        // platforms.append("Linux")
    }

    if package.contains(".android") {
        printC("Android is not supported, skipped", color: CLIColors.orange)
        // platforms.append("Android")
    }

    if platforms.isEmpty {
        printC("No platforms found in Package.swift, defaulting to all", color: CLIColors.orange)
        platforms = ["iOS", "tvOS", "xrOS", "watchOS", "macOS"]
    }

    printC("Build \(productName) for \(platforms.joined(separator: ", "))...")

    for (number, platform) in platforms.enumerated() {
        printC("Building \(productName) on \(platform). (\(number + 1)/\(platforms.count))", terminator: "\r")
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [
            "xcrun",
            "xcodebuild",
            "clean",
            "build",
            "-quiet",
            "-scheme", productName,
            "-destination", "generic/platform=\(platform)"
        ]
        process.launch()
        process.waitUntilExit()
        // Check if the process was successful
        if process.terminationStatus != 0 {
            fails += 1
            printC("Failed to build for \(platform) (\(number + 1)/\(platforms.count))", color: CLIColors.red)
        } else {
            printC("Build for \(platform) successful (\(number + 1)/\(platforms.count)) ", color: CLIColors.green)
        }
    }

    if fails > 0 {
        printC("Failed to build for \(fails) platforms", color: CLIColors.red)
    } else {
        printC("Build for all platforms successful", color: CLIColors.green)
    }

    exit(0)
}

if ["test", "--test", "-t"].contains(CommandLine.arguments[1]) {
    testSwiftPackage(arguments: Array(CommandLine.arguments.dropFirst(2)))
    exit(0)
}

func header() {
    // Search for all .swift files
    let enumerator = fileManager.enumerator(atPath: ".")
    while let element = enumerator?.nextObject() as? String {
        if element.hasSuffix(".swift") {
            var headerLines = 0

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: Date())

            var createdBy = "//  Created by Wesley de Groot on \(date)."
            let file = element
            let path = URL(fileURLWithPath: file)
            guard let contents = try? String(contentsOf: path, encoding: .utf8) else {
                printC("Failed to read \(file)", color: CLIColors.red)
                continue
            }
            let filename = file.components(separatedBy: "/").last
            var lines = contents.components(separatedBy: .newlines)

            if lines.isEmpty {
                break
            }

            if lines[0].hasPrefix("#!") || file == "Package.swift" {
                continue
            }

            for line in lines {
                if line.hasPrefix("//") {
                    if line.contains("Created by") {
                        createdBy = line
                    }

                    headerLines += 1
                } else {
                    break
                }
            }

            lines.removeFirst(Int(headerLines))

            let header = [
                "//",
                "//  \(filename ?? "")",
                "//  \(productName)",
                "//",
                createdBy,
                "//  https://wesleydegroot.nl",
                "//",
                "//  https://github.com/0xWDG/\(productName)",
                "//  MIT License",
                "//"
            ]

            lines.insert(contentsOf: header, at: 0)
            let newContents = lines.joined(separator: "\n")
            do {
                try newContents.write(to: path, atomically: true, encoding: .utf8)
                printC("Updated header for \(file)", color: CLIColors.green)
            } catch {
                printC("Failed to update header for \(file)", color: CLIColors.red)
            }
        }
    }
}

func generateMITLicense() {
    let license = """
MIT License

Copyright (c) \(Calendar.current.component(.year, from: Date())) Wesley de Groot, email@WesleydeGroot.nl

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

    do {
        try license.write(to: URL(fileURLWithPath: "LICENCE.md"), atomically: true, encoding: .utf8)
        printC("Generated LICENCE.md", color: CLIColors.green)
    } catch {
        printC("Failed to generate LICENCE.md", color: CLIColors.red)
    }
}

func generateReadme() {
    var readme = """
# PACKAGENAME

PACKAGENAME is a Swift Package for ...

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2FPACKAGENAME%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/0xWDG/PACKAGENAME)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2FPACKAGENAME%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/0xWDG/PACKAGENAME)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/0xWDG/PACKAGENAME)

## Requirements

- Swift 5.8+ (Xcode 15+)
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+

## Installation (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/0xWDG/PACKAGENAME.git", branch: "main"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "PACKAGENAME", package: "PACKAGENAME"),
    ]),
]
```

## Installation (Xcode)

1. In Xcode, open your project and navigate to **File** → **Swift Packages** → **Add Package Dependency...**
2. Paste the repository URL (`https://github.com/0xWDG/PACKAGENAME`) and click **Next**.
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

🦋 [@0xWDG](https://bsky.app/profile/0xWDG.bsky.social)
🐘 [mastodon.social/@0xWDG](https://mastodon.social/@0xWDG)
🐦 [@0xWDG](https://x.com/0xWDG)
🧵 [@0xWDG](https://www.threads.net/@0xWDG)
🌐 [wesleydegroot.nl](https://wesleydegroot.nl)
🤖 [Discord](https://discordapp.com/users/918438083861573692)

Interested learning more about Swift? [Check out my blog](https://wesleydegroot.nl/blog/).
"""

    readme = readme.replacingOccurrences(of: "PACKAGENAME", with: productName)

    do {
        try readme.write(to: URL(fileURLWithPath: "README.md"), atomically: true, encoding: .utf8)
        printC("Generated README.md", color: CLIColors.green)
    } catch {
        printC("Failed to generate README.md", color: CLIColors.red)
    }
}

func generateEditorConfig() {
    let editorConfig = """
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
"""

    do {
        try editorConfig.write(to: URL(fileURLWithPath: ".editorconfig"), atomically: true, encoding: .utf8)
        printC("Generated .editorconfig", color: CLIColors.green)
    } catch {
        printC("Failed to generate .editorconfig", color: CLIColors.red)
    }
}

func generateGitIgnore() {
    let gitIgnore = """
## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

### Swift Package Manager
Packages/
Package.pins
Package.resolved
# *.xcodeproj
#
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
.swiftpm
.build/

### CocoaPods
Pods/
*.xcworkspace

### Carthage
Carthage/Checkouts
Carthage/Build/

### Accio dependency management
Dependencies/
.accio/

### fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

### Code Injection
iOSInjectionProject/
"""

    do {
        try gitIgnore.write(to: URL(fileURLWithPath: ".gitignore"), atomically: true, encoding: .utf8)
        printC("Generated .gitignore", color: CLIColors.green)
    } catch {
        printC("Failed to generate .gitignore", color: CLIColors.red)
    }
}

func generateSwiftLint() {
    let swiftLint = """
excluded:
  - "*resource_bundle_accessor*" # SwiftPM Generated
  - ".build/*"

opt_in_rules:
   - missing_docs
   - empty_count
   - empty_string
   - toggle_bool
   - unused_optional_binding
   - valid_ibinspectable
   - modifier_order
   - first_where
   - fatal_error_message
   - force_unwrapping
"""

    do {
        try swiftLint.write(to: URL(fileURLWithPath: ".swiftlint.yml"), atomically: true, encoding: .utf8)
        printC("Generated .swiftlint.yml", color: CLIColors.green)
    } catch {
        printC("Failed to generate .swiftlint.yml", color: CLIColors.red)
    }
}

func testSwiftPackage(arguments: [String]) {
    if !fileManager.fileExists(atPath: "Package.swift") {
        printC("Package.swift not found", color: CLIColors.red)
        exit(2)
    }

    printC("Testing \(productName)...")

    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["swift", "test"] + arguments
    process.launch()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        printC("Tests failed", color: CLIColors.red)
        exit(process.terminationStatus)
    }

    printC("Tests passed", color: CLIColors.green)
}

enum XcodePackageInstallerError: Error, CustomStringConvertible {
    case noProjectFound
    case multipleProjectsFound([String])
    case missingPBXProject
    case malformedProject(String)
    case noLinkableTarget
    case commandFailed(String)

    var description: String {
        switch self {
        case .noProjectFound:
            return "No .xcodeproj found in the current directory."
        case .multipleProjectsFound(let projects):
            return "Multiple .xcodeproj files found. Run this from a directory with exactly one project: \(projects.joined(separator: ", "))"
        case .missingPBXProject:
            return "Could not find the PBXProject object in project.pbxproj."
        case .malformedProject(let detail):
            return "Malformed project.pbxproj: \(detail)"
        case .noLinkableTarget:
            return "No PBXNativeTarget with a Frameworks build phase was found."
        case .commandFailed(let detail):
            return detail
        }
    }
}

struct XcodePackageSemanticVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let original: String

    static func < (lhs: XcodePackageSemanticVersion, rhs: XcodePackageSemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

struct XcodePackageRequirement {
    let lines: [String]
}

struct XcodePackageManifest: Decodable {
    struct Product: Decodable {
        let name: String
        let type: ProductType
    }

    struct ProductType: Decodable {
        let library: [String]?
    }

    let products: [Product]
}

struct XcodeNativeTarget {
    let id: String
    let name: String
    let frameworksBuildPhaseID: String
}

func runXcodePackageInstallerCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
    let process = Process()
    let output = Pipe()
    let error = Pipe()

    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = error

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    guard process.terminationStatus == 0 else {
        let command = ([launchPath] + arguments).joined(separator: " ")
        throw XcodePackageInstallerError.commandFailed("Command failed: \(command)\n\(stderr.isEmpty ? stdout : stderr)")
    }

    return stdout
}

func findXcodeProject(in directory: URL) throws -> URL {
    let contents = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    let projects = contents
        .filter { $0.pathExtension == "xcodeproj" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    if projects.isEmpty {
        throw XcodePackageInstallerError.noProjectFound
    }

    if projects.count > 1 {
        throw XcodePackageInstallerError.multipleProjectsFound(projects.map(\.lastPathComponent))
    }

    return projects[0]
}

func swiftPackageName(from packageURL: String) -> String {
    let trimmed = packageURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let lastComponent = trimmed.split(separator: "/").last.map(String.init) ?? "Package"
    return lastComponent.hasSuffix(".git") ? String(lastComponent.dropLast(4)) : lastComponent
}

func normalizedSwiftPackageURL(from input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.contains("://") || trimmed.hasPrefix("git@") || trimmed.hasPrefix("ssh://") {
        return trimmed
    }

    if trimmed.hasPrefix("github.com/") {
        return "https://\(trimmed)"
    }

    let components = trimmed
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .split(separator: "/")

    if components.count == 2,
       !components[0].isEmpty,
       !components[1].isEmpty {
        return "https://github.com/\(components[0])/\(components[1])"
    }

    if components.count == 1,
       let repo = components.first,
       !repo.isEmpty {
        return "https://github.com/0xWDG/\(repo)"
    }

    return trimmed
}

func possibleSwiftPackageProductNames(from packageName: String) -> [String] {
    let withoutSwiftPrefix = packageName.hasPrefix("swift-")
        ? String(packageName.dropFirst("swift-".count))
        : packageName
    let separators = CharacterSet(charactersIn: "-_")

    func pascalCase(_ value: String) -> String {
        value
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }

    return Array(Set([
        packageName,
        withoutSwiftPrefix,
        pascalCase(packageName),
        pascalCase(withoutSwiftPrefix)
    ])).filter { !$0.isEmpty }
}

func libraryProducts(forPackageURL packageURL: String, fallbackPackageName: String) -> [String] {
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("swift-package-installer-\(UUID().uuidString)")

    defer {
        try? fileManager.removeItem(at: temporaryDirectory)
    }

    do {
        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let cloneURL = temporaryDirectory.appendingPathComponent("Package")
        _ = try runXcodePackageInstallerCommand("/usr/bin/git", [
            "clone",
            "--depth",
            "1",
            packageURL,
            cloneURL.path
        ])

        let manifestJSON = try runXcodePackageInstallerCommand("/usr/bin/swift", [
            "package",
            "--package-path",
            cloneURL.path,
            "dump-package"
        ])

        let manifest = try JSONDecoder().decode(
            XcodePackageManifest.self,
            from: Data(manifestJSON.utf8)
        )

        let libraries = manifest.products
            .filter { $0.type.library != nil }
            .map(\.name)

        if !libraries.isEmpty {
            return libraries
        }
    } catch {
        // Fall back to common package-to-product naming conventions when the
        // remote manifest cannot be inspected in this environment.
    }

    return possibleSwiftPackageProductNames(from: fallbackPackageName)
}

func parseXcodePackageSemanticVersion(_ tag: String) -> XcodePackageSemanticVersion? {
    let clean = tag
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "refs/tags/", with: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

    let parts = clean.split(separator: ".")
    guard parts.count >= 2 else { return nil }

    let numericParts = parts.prefix(3).map { part -> Int? in
        let digits = part.prefix { $0.isNumber }
        return Int(digits)
    }

    guard
        let major = numericParts[safe: 0] ?? nil,
        let minor = numericParts[safe: 1] ?? nil
    else {
        return nil
    }

    let patch = (numericParts[safe: 2] ?? nil) ?? 0
    return XcodePackageSemanticVersion(major: major, minor: minor, patch: patch, original: clean)
}

func defaultBranch(forPackageURL packageURL: String) -> String? {
    guard let output = try? runXcodePackageInstallerCommand("/usr/bin/git", ["ls-remote", "--symref", packageURL, "HEAD"]) else {
        return nil
    }

    for line in output.split(separator: "\n") {
        guard line.hasPrefix("ref: refs/heads/") else { continue }
        let pieces = line.split(separator: "\t")
        guard let ref = pieces.first else { continue }
        return ref
            .replacingOccurrences(of: "ref: refs/heads/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return nil
}

func packageRequirement(forPackageURL packageURL: String) -> XcodePackageRequirement {
    if let output = try? runXcodePackageInstallerCommand("/usr/bin/git", ["ls-remote", "--tags", "--refs", packageURL]) {
        let versions = output
            .split(separator: "\n")
            .compactMap { line -> XcodePackageSemanticVersion? in
                guard let ref = line.split(separator: "\t").last else { return nil }
                return parseXcodePackageSemanticVersion(String(ref))
            }

        if let latest = versions.max() {
            return XcodePackageRequirement(lines: [
                "kind = upToNextMajorVersion;",
                "minimumVersion = \(latest.original);"
            ])
        }
    }

    let branch = defaultBranch(forPackageURL: packageURL) ?? "main"
    return XcodePackageRequirement(lines: [
        "branch = \(branch);",
        "kind = branch;"
    ])
}

func makeXcodeObjectID(existingIn project: String) -> String {
    var id = ""
    repeat {
        id = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24).uppercased()
    } while project.contains(id)
    return id
}

func xcodeObjectID(from object: String) -> String? {
    object.split(separator: "=", maxSplits: 1).first?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .split(separator: " ")
        .first
        .map(String.init)
}

func xcodeObjectComment(from object: String) -> String? {
    guard let start = object.range(of: "/*"),
          let end = object.range(of: "*/", range: start.upperBound..<object.endIndex)
    else {
        return nil
    }

    return String(object[start.upperBound..<end.lowerBound])
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func xcodeObjectRange(containing marker: String, in text: String) -> Range<String.Index>? {
    guard let markerRange = text.range(of: marker) else { return nil }

    var searchStart = text.startIndex
    var objectStart: String.Index?
    while let range = text.range(of: "= {", range: searchStart..<markerRange.lowerBound) {
        objectStart = range.lowerBound
        searchStart = range.upperBound
    }

    guard let assignmentStart = objectStart else { return nil }
    let start = text[..<assignmentStart].lastIndex(of: "\n")
        .map { text.index(after: $0) }
        ?? text.startIndex

    var index = assignmentStart
    var depth = 0
    while index < text.endIndex {
        let character = text[index]
        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                guard let semicolon = text[index...].firstIndex(of: ";") else { return nil }
                return start..<text.index(after: semicolon)
            }
        }
        index = text.index(after: index)
    }

    return nil
}

func xcodeObjectRange(withID id: String, in text: String) -> Range<String.Index>? {
    guard let idRange = text.range(of: "\t\t\(id)") ?? text.range(of: "\n\t\t\(id)") else {
        return nil
    }

    guard let assignmentRange = text.range(of: "= {", range: idRange.upperBound..<text.endIndex) else {
        return nil
    }

    var index = assignmentRange.lowerBound
    var depth = 0
    while index < text.endIndex {
        let character = text[index]
        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                guard let semicolon = text[index...].firstIndex(of: ";") else { return nil }
                return idRange.lowerBound..<text.index(after: semicolon)
            }
        }
        index = text.index(after: index)
    }

    return nil
}

func xcodeObjectRanges(containing marker: String, in text: String) -> [Range<String.Index>] {
    var ranges: [Range<String.Index>] = []
    var searchStart = text.startIndex

    while let markerRange = text.range(of: marker, range: searchStart..<text.endIndex) {
        var assignmentSearchStart = text.startIndex
        var assignmentStart: String.Index?

        while let assignmentRange = text.range(of: "= {", range: assignmentSearchStart..<markerRange.lowerBound) {
            assignmentStart = assignmentRange.lowerBound
            assignmentSearchStart = assignmentRange.upperBound
        }

        if let assignmentStart {
            let objectStart = text[..<assignmentStart].lastIndex(of: "\n")
                .map { text.index(after: $0) }
                ?? text.startIndex

            var index = assignmentStart
            var depth = 0

            while index < text.endIndex {
                let character = text[index]
                if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth -= 1
                    if depth == 0 {
                        if let semicolon = text[index...].firstIndex(of: ";") {
                            ranges.append(objectStart..<text.index(after: semicolon))
                            searchStart = text.index(after: semicolon)
                        } else {
                            searchStart = markerRange.upperBound
                        }
                        break
                    }
                }
                index = text.index(after: index)
            }
        } else {
            searchStart = markerRange.upperBound
        }

        if searchStart <= markerRange.lowerBound {
            searchStart = markerRange.upperBound
        }
    }

    return ranges
}

func addPackageReferenceListEntry(projectObject: String, packageID: String, packageName: String) throws -> String {
    let entry = "\t\t\t\t\(packageID) /* XCRemoteSwiftPackageReference \"\(packageName)\" */,"

    if let referencesRange = projectObject.range(of: "packageReferences = (") {
        guard let closeRange = projectObject.range(of: "\n\t\t\t);", range: referencesRange.upperBound..<projectObject.endIndex) else {
            throw XcodePackageInstallerError.malformedProject("packageReferences list is missing its closing marker.")
        }

        var updated = projectObject
        updated.insert(contentsOf: "\n\(entry)", at: closeRange.lowerBound)
        return updated
    }

    let insertion: String
    if let productRefRange = projectObject.range(of: "\n\t\t\tproductRefGroup = ") {
        insertion = """

\t\t\tpackageReferences = (
\(entry)
\t\t\t);
"""
        var updated = projectObject
        updated.insert(contentsOf: insertion, at: productRefRange.lowerBound)
        return updated
    }

    guard let closingRange = projectObject.range(of: "\n\t\t};", options: .backwards) else {
        throw XcodePackageInstallerError.malformedProject("PBXProject object is missing its closing marker.")
    }

    insertion = """

\t\t\tpackageReferences = (
\(entry)
\t\t\t);
"""
    var updated = projectObject
    updated.insert(contentsOf: insertion, at: closingRange.lowerBound)
    return updated
}

func xcodeListBlockRange(named name: String, in object: String) -> Range<String.Index>? {
    guard let start = object.range(of: "\(name) = (") else { return nil }
    return object.range(of: "\n\t\t\t);", range: start.upperBound..<object.endIndex)
        .map { start.lowerBound..<$0.upperBound }
}

func addXcodeListEntry(object: String, listName: String, entry: String) throws -> String {
    if let blockRange = xcodeListBlockRange(named: listName, in: object) {
        if object[blockRange].contains(entry) {
            return object
        }

        guard let closeRange = object.range(of: "\n\t\t\t);", range: blockRange.lowerBound..<blockRange.upperBound) else {
            throw XcodePackageInstallerError.malformedProject("\(listName) list is missing its closing marker.")
        }

        var updated = object
        updated.insert(contentsOf: "\n\(entry)", at: closeRange.lowerBound)
        return updated
    }

    guard let closingRange = object.range(of: "\n\t\t};", options: .backwards) else {
        throw XcodePackageInstallerError.malformedProject("object is missing its closing marker.")
    }

    let insertion = """

\t\t\t\(listName) = (
\(entry)
\t\t\t);
"""
    var updated = object
    updated.insert(contentsOf: insertion, at: closingRange.lowerBound)
    return updated
}

func nativeTargets(inXcodeProject project: String) -> [XcodeNativeTarget] {
    xcodeObjectRanges(containing: "isa = PBXNativeTarget;", in: project).compactMap { range in
        let object = String(project[range])
        guard let id = xcodeObjectID(from: object) else { return nil }
        let name = xcodeObjectComment(from: object) ?? id
        guard
            let buildPhasesRange = xcodeListBlockRange(named: "buildPhases", in: object),
            let frameworksLine = object[buildPhasesRange]
                .split(separator: "\n")
                .first(where: { $0.contains("/* Frameworks */") }),
            let phaseID = frameworksLine
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
                .first
                .map(String.init)
        else {
            return nil
        }

        return XcodeNativeTarget(
            id: id,
            name: name,
            frameworksBuildPhaseID: phaseID
        )
    }
}

func existingPackageReferenceID(inXcodeProject project: String, packageURL: String) -> String? {
    xcodeObjectRanges(containing: "isa = XCRemoteSwiftPackageReference;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("repositoryURL = \(packageURL);")
                || object.contains("repositoryURL = \"\(packageURL)\";")
            else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}

func existingProductDependencyID(inXcodeProject project: String, packageID: String, productName: String) -> String? {
    xcodeObjectRanges(containing: "isa = XCSwiftPackageProductDependency;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("package = \(packageID)")
                && object.contains("productName = \(productName);")
            else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}

func existingBuildFileID(inXcodeProject project: String, productDependencyID: String) -> String? {
    xcodeObjectRanges(containing: "isa = PBXBuildFile;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("productRef = \(productDependencyID)") else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}

func packageReferenceSection(packageID: String, packageName: String, packageURL: String, requirement: XcodePackageRequirement) -> String {
    let requirementBody = requirement.lines.map { "\t\t\t\t\($0)" }.joined(separator: "\n")
    return """

/* Begin XCRemoteSwiftPackageReference section */
\t\t\(packageID) /* XCRemoteSwiftPackageReference "\(packageName)" */ = {
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = \(packageURL);
\t\t\trequirement = {
\(requirementBody)
\t\t\t};
\t\t};
/* End XCRemoteSwiftPackageReference section */

"""
}

func packageReferenceObject(packageID: String, packageName: String, packageURL: String, requirement: XcodePackageRequirement) -> String {
    let requirementBody = requirement.lines.map { "\t\t\t\t\($0)" }.joined(separator: "\n")
    return """
\t\t\(packageID) /* XCRemoteSwiftPackageReference "\(packageName)" */ = {
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = \(packageURL);
\t\t\trequirement = {
\(requirementBody)
\t\t\t};
\t\t};

"""
}

func buildFileObject(buildFileID: String, productDependencyID: String, productName: String) -> String {
    """
\t\t\(buildFileID) /* \(productName) in Frameworks */ = {isa = PBXBuildFile; productRef = \(productDependencyID) /* \(productName) */; };

"""
}

func swiftPackageProductDependencyObject(productDependencyID: String, packageID: String, packageName: String, productName: String) -> String {
    """
\t\t\(productDependencyID) /* \(productName) */ = {
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = \(packageID) /* XCRemoteSwiftPackageReference "\(packageName)" */;
\t\t\tproductName = \(productName);
\t\t};

"""
}

func insertXcodeObject(_ object: String, intoSectionNamed section: String, in project: String, before fallbackSection: String) throws -> String {
    let endMarker = "/* End \(section) section */"
    if let endSection = project.range(of: endMarker) {
        var updated = project
        updated.insert(contentsOf: object, at: endSection.lowerBound)
        return updated
    }

    let fullSection = """

/* Begin \(section) section */
\(object)/* End \(section) section */

"""

    guard let insertionPoint = project.range(of: "/* Begin \(fallbackSection) section */")?.lowerBound
        ?? project.range(of: "/* End PBXProject section */")?.upperBound
    else {
        throw XcodePackageInstallerError.malformedProject("could not find a safe place to insert the \(section) section.")
    }

    var updated = project
    updated.insert(contentsOf: fullSection, at: insertionPoint)
    return updated
}

func insertPackageReferenceObject(into project: String, packageID: String, packageName: String, packageURL: String, requirement: XcodePackageRequirement) throws -> String {
    if let endSection = project.range(of: "/* End XCRemoteSwiftPackageReference section */") {
        var updated = project
        updated.insert(
            contentsOf: packageReferenceObject(
                packageID: packageID,
                packageName: packageName,
                packageURL: packageURL,
                requirement: requirement
            ),
            at: endSection.lowerBound
        )
        return updated
    }

    guard let insertionPoint = project.range(of: "/* Begin XCBuildConfiguration section */")?.lowerBound
        ?? project.range(of: "/* End PBXProject section */")?.upperBound
    else {
        throw XcodePackageInstallerError.malformedProject("could not find a safe place to insert the package reference section.")
    }

    var updated = project
    updated.insert(
        contentsOf: packageReferenceSection(
            packageID: packageID,
            packageName: packageName,
            packageURL: packageURL,
            requirement: requirement
        ),
        at: insertionPoint
    )
    return updated
}

func addPackageProductToTarget(
    project: String,
    target: XcodeNativeTarget,
    packageID: String,
    packageName: String,
    productName: String
) throws -> String {
    var updated = project
    let productDependencyID = existingProductDependencyID(
        inXcodeProject: updated,
        packageID: packageID,
        productName: productName
    ) ?? makeXcodeObjectID(existingIn: updated)
    let buildFileID = existingBuildFileID(
        inXcodeProject: updated,
        productDependencyID: productDependencyID
    ) ?? makeXcodeObjectID(existingIn: updated + productDependencyID)

    guard let currentTargetRange = xcodeObjectRange(withID: target.id, in: updated) else {
        throw XcodePackageInstallerError.malformedProject("could not find native target \(target.name).")
    }

    let targetObject = String(updated[currentTargetRange])
    let dependencyEntry = "\t\t\t\t\(productDependencyID) /* \(productName) */,"
    let updatedTarget = try addXcodeListEntry(
        object: targetObject,
        listName: "packageProductDependencies",
        entry: dependencyEntry
    )
    updated.replaceSubrange(currentTargetRange, with: updatedTarget)

    guard let phaseRange = xcodeObjectRange(withID: target.frameworksBuildPhaseID, in: updated) else {
        throw XcodePackageInstallerError.malformedProject("could not find Frameworks build phase for target \(target.name).")
    }

    let phaseObject = String(updated[phaseRange])
    let buildFileEntry = "\t\t\t\t\(buildFileID) /* \(productName) in Frameworks */,"
    let updatedPhase = try addXcodeListEntry(
        object: phaseObject,
        listName: "files",
        entry: buildFileEntry
    )
    updated.replaceSubrange(phaseRange, with: updatedPhase)

    if existingBuildFileID(inXcodeProject: updated, productDependencyID: productDependencyID) == nil {
        updated = try insertXcodeObject(
            buildFileObject(
                buildFileID: buildFileID,
                productDependencyID: productDependencyID,
                productName: productName
            ),
            intoSectionNamed: "PBXBuildFile",
            in: updated,
            before: "PBXFileReference"
        )
    }

    if existingProductDependencyID(inXcodeProject: updated, packageID: packageID, productName: productName) == nil {
        updated = try insertXcodeObject(
            swiftPackageProductDependencyObject(
                productDependencyID: productDependencyID,
                packageID: packageID,
                packageName: packageName,
                productName: productName
            ),
            intoSectionNamed: "XCSwiftPackageProductDependency",
            in: updated,
            before: "XCBuildConfiguration"
        )
    }

    return updated
}

func installSwiftPackageInXcodeProject(packageURL packageInput: String) throws {
    let packageURL = normalizedSwiftPackageURL(from: packageInput)
    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let projectURL = try findXcodeProject(in: currentDirectory)
    let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
    var project = try String(contentsOf: pbxprojURL, encoding: .utf8)

    let name = swiftPackageName(from: packageURL)
    let existingID = existingPackageReferenceID(inXcodeProject: project, packageURL: packageURL)
    let id = existingID ?? makeXcodeObjectID(existingIn: project)
    let resolvedRequirement = packageRequirement(forPackageURL: packageURL)
    let targets = nativeTargets(inXcodeProject: project)
    guard !targets.isEmpty else {
        throw XcodePackageInstallerError.noLinkableTarget
    }

    let productNames = libraryProducts(forPackageURL: packageURL, fallbackPackageName: name)

    if existingID == nil {
        guard let pbxProjectRange = xcodeObjectRange(containing: "isa = PBXProject;", in: project) else {
            throw XcodePackageInstallerError.missingPBXProject
        }

        let projectObject = String(project[pbxProjectRange])
        let updatedProjectObject = try addPackageReferenceListEntry(
            projectObject: projectObject,
            packageID: id,
            packageName: name
        )
        project.replaceSubrange(pbxProjectRange, with: updatedProjectObject)
        project = try insertPackageReferenceObject(
            into: project,
            packageID: id,
            packageName: name,
            packageURL: packageURL,
            requirement: resolvedRequirement
        )
    }

    for target in targets {
        for productName in productNames {
            project = try addPackageProductToTarget(
                project: project,
                target: target,
                packageID: id,
                packageName: name,
                productName: productName
            )
        }
    }

    let backupURL = pbxprojURL.deletingLastPathComponent()
        .appendingPathComponent("project.pbxproj.backup-\(Int(Date().timeIntervalSince1970))")
    try fileManager.copyItem(at: pbxprojURL, to: backupURL)
    try project.write(to: pbxprojURL, atomically: true, encoding: .utf8)

    printC("Installed \(name) in \(projectURL.lastPathComponent)", color: CLIColors.green)
    printC("Linked products: \(productNames.joined(separator: ", "))", color: CLIColors.green)
    printC("Targets: \(targets.map(\.name).joined(separator: ", "))", color: CLIColors.green)
    printC("Backup: \(backupURL.path)", color: CLIColors.yellow)
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

if CommandLine.arguments[1] == "executable" {
    let temporarySource = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("spm-\(UUID().uuidString).swift")

    do {
        let script = try String(contentsOf: URL(fileURLWithPath: CommandLine.arguments[0]), encoding: .utf8)
        try script.write(to: temporarySource, atomically: true, encoding: .utf8)
    } catch {
        printC("Failed to prepare script for compilation", color: CLIColors.red)
        exit(4)
    }

    defer {
        try? fileManager.removeItem(at: temporarySource)
    }

    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["swiftc", temporarySource.path, "-o", "spm"]
    process.launch()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        printC("Failed to compile script", color: CLIColors.red)
        exit(4)
    } else {
        printC("Script compiled successfully", color: CLIColors.green)
    }
}
