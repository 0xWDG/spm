//
//  PackageCommands.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public extension spm {
/// Creates and bootstraps a Swift package with the project defaults.
static func createPackage(named name: String) {
    productName = name

    if !fileManager.fileExists(atPath: "Package.swift") {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["swift", "package", "init", "--name", productName]
        process.launch()
        process.waitUntilExit()
    }

    do {
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
        try newPackage.write(to: URL(fileURLWithPath: "Package.swift"), atomically: true, encoding: .utf8)
        printC("Downgraded swift-tools-version to 5.8.0", color: CLIColors.green)
    } catch {
        printC("Failed to update Package.swift", color: CLIColors.red)
    }

    let spi = """
version: 1
builder:
  configs:
    - documentation_targets: [\(productName)]
"""
    try? spi.write(to: URL(fileURLWithPath: ".spi.yml"), atomically: true, encoding: .utf8)

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

/// Builds the package for platforms detected in Package.swift.
static func buildPackageForDetectedPlatforms() {
    if !fileManager.fileExists(atPath: "Package.swift") {
        printC("Package.swift not found", color: CLIColors.red)
        exit(2)
    }

    let package = (try? String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8)) ?? ""
    let platforms = detectedBuildPlatforms(in: package)

    printC("Build \(productName) for \(platforms.joined(separator: ", "))...")

    let fails = platforms
        .enumerated()
        .filter { !buildPackage(platform: $0.element, number: $0.offset, total: platforms.count) }
        .count

    if fails > 0 {
        printC("Failed to build for \(fails) platforms", color: CLIColors.red)
    } else {
        printC("Build for all platforms successful", color: CLIColors.green)
    }
}

/// Returns supported build platforms detected in a package manifest.
static func detectedBuildPlatforms(in package: String) -> [String] {
    let supportedPlatforms = [
        (marker: ".iOS", platform: "iOS"),
        (marker: ".macOS", platform: "macOS"),
        (marker: ".watchOS", platform: "watchOS"),
        (marker: ".visionOS", platform: "xrOS"),
        (marker: ".tvOS", platform: "tvOS"),
        (marker: ".maccatalyst", platform: "MacCatalyst")
    ]
    let platforms = supportedPlatforms
        .filter { package.contains($0.marker) }
        .map(\.platform)

    printUnsupportedPlatforms(in: package)

    if platforms.isEmpty {
        printC("No platforms found in Package.swift, defaulting to all", color: CLIColors.orange)
        return ["iOS", "tvOS", "xrOS", "watchOS", "macOS"]
    }

    return platforms
}

/// Prints unsupported package platforms detected in the package manifest.
static func printUnsupportedPlatforms(in package: String) {
    let unsupportedPlatforms = [
        (marker: ".driverkit", name: "DriverKit"),
        (marker: ".linux", name: "Linux"),
        (marker: ".android", name: "Android")
    ]

    unsupportedPlatforms
        .filter { package.contains($0.marker) }
        .forEach { printC("\($0.name) is not supported, skipped", color: CLIColors.orange) }
}

/// Builds one package platform and returns whether it succeeded.
static func buildPackage(platform: String, number: Int, total: Int) -> Bool {
    let current = number + 1
    let progress = progressBar(current: current, total: total)
    let message = "\(progress) Building \(productName) for \(platform)"

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
    let terminationStatus = runProcessWithSpinner(process, message: message)

    if terminationStatus == 0 {
        printC("\(progress) Build for \(platform) successful", color: CLIColors.green)
        return true
    }

    printC("\(progress) Failed to build for \(platform)", color: CLIColors.red)
    return false
}

/// Runs `swift test` with any forwarded test arguments.
static func testSwiftPackage(arguments: [String]) {
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

/// Builds static web documentation with DocC.
static func buildDocumentation(arguments: [String]) {
    if !fileManager.fileExists(atPath: "Package.swift") {
        printC("Package.swift not found", color: CLIColors.red)
        exit(2)
    }

    let options = documentationOptions(from: arguments)
    let workingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let scratchDirectory = workingDirectory
        .appendingPathComponent(".build", isDirectory: true)
        .appendingPathComponent("spm-documentation", isDirectory: true)
    let symbolGraphDirectory = scratchDirectory.appendingPathComponent("SymbolGraphs", isDirectory: true)
    let fallbackCatalog = scratchDirectory.appendingPathComponent("\(options.target).docc", isDirectory: true)
    let catalog = documentationCatalog(for: options.target) ?? fallbackCatalog

    prepareDocumentationDirectories(
        scratchDirectory: scratchDirectory,
        symbolGraphDirectory: symbolGraphDirectory,
        fallbackCatalog: fallbackCatalog
    )
    buildDocumentationSymbolGraphs(options: options, symbolGraphDirectory: symbolGraphDirectory)
    convertDocumentation(
        options: options,
        catalog: catalog,
        symbolGraphDirectory: symbolGraphDirectory
    )
}

/// Prepares the temporary directories used to build documentation.
static func prepareDocumentationDirectories(
    scratchDirectory: URL,
    symbolGraphDirectory: URL,
    fallbackCatalog: URL
) {
    do {
        try fileManager.removeItem(at: scratchDirectory)
    } catch CocoaError.fileNoSuchFile {
    } catch {
        printC("Failed to clear documentation scratch directory: \(error)", color: CLIColors.red)
        exit(3)
    }

    do {
        try fileManager.createDirectory(at: symbolGraphDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: fallbackCatalog, withIntermediateDirectories: true)
    } catch {
        printC("Failed to prepare documentation directories: \(error)", color: CLIColors.red)
        exit(3)
    }
}

/// Builds symbol graphs for DocC conversion.
static func buildDocumentationSymbolGraphs(options: DocumentationOptions, symbolGraphDirectory: URL) {
    printC("Generating symbol graphs for \(options.target)...")
    let symbolGraphStatus = runProcess(
        launchPath: "/usr/bin/env",
        arguments: [
            "swift",
            "build",
            "--target", options.target,
            "-Xswiftc", "-emit-symbol-graph",
            "-Xswiftc", "-emit-symbol-graph-dir",
            "-Xswiftc", symbolGraphDirectory.path
        ]
    )

    guard symbolGraphStatus == 0 else {
        printC("Failed to generate symbol graphs", color: CLIColors.red)
        exit(symbolGraphStatus)
    }
}

/// Converts symbol graphs and the documentation catalog into static web documentation.
static func convertDocumentation(
    options: DocumentationOptions,
    catalog: URL,
    symbolGraphDirectory: URL
) {
    printC("Building static documentation in \(options.outputPath)...")
    let doccStatus = runProcess(
        launchPath: "/usr/bin/xcrun",
        arguments: [
            "docc",
            "convert",
            catalog.path,
            "--additional-symbol-graph-dir", symbolGraphDirectory.path,
            "--output-path", options.outputPath,
            "--fallback-display-name", options.target,
            "--fallback-bundle-identifier", "nl.wesleydegroot.\(options.target)",
            "--fallback-default-module-kind", "Tool",
            "--hosting-base-path", options.hostingBasePath,
            "--transform-for-static-hosting"
        ]
    )

    guard doccStatus == 0 else {
        printC("Failed to build documentation", color: CLIColors.red)
        exit(doccStatus)
    }

    printC("Documentation built at \(options.outputPath)", color: CLIColors.green)
}

/// Compiles all source files into a local executable named `spm`.
static func compileExecutable() {
    let sourceDirectory = URL(fileURLWithPath: "Sources/spm")
    let packageSources = try? fileManager.contentsOfDirectory(
        at: sourceDirectory,
        includingPropertiesForKeys: nil
    )
    guard let sources = packageSources?
        .filter({ $0.pathExtension == "swift" })
        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
        printC("Failed to find Sources/spm/*.swift", color: CLIColors.red)
        exit(4)
    }

    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["swiftc"] + sources.map(\.path) + ["-o", "spm"]
    process.launch()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        printC("Failed to compile executable", color: CLIColors.red)
        exit(4)
    } else {
        printC("Executable compiled successfully", color: CLIColors.green)
    }
}

}
