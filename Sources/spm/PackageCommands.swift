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

/// Options for creating and customizing a Swift package.
public struct PackageCreationOptions: Equatable {
    /// Package name.
    public let name: String
    /// SwiftPM package template type.
    public let type: String
    /// Destination directory.
    public let path: String
}

public extension SPM {
/// Creates and bootstraps a Swift package with the project defaults.
static func createPackage(named name: String) throws {
    try createPackage(options: PackageCreationOptions(name: name, type: "library", path: "."))
}

/// Creates and bootstraps a Swift package with explicit type and destination options.
static func createPackage(options: PackageCreationOptions) throws {
    let supportedTypes = Set(["library", "executable", "tool", "empty"])
    guard supportedTypes.contains(options.type) else {
        throw SPMCommandError.usage("Unsupported package type: \(options.type).")
    }

    let destination = URL(fileURLWithPath: options.path, relativeTo: projectURL()).standardizedFileURL
    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    let runtime = SPMRuntime(
        fileManager: fileManager,
        workingDirectory: destination,
        environment: SPMRuntime.current.environment
    )
    try withRuntime(runtime) {
        try createPackageInCurrentRuntime(named: options.name, type: options.type)
    }
}

/// Creates a package in the active runtime directory.
private static func createPackageInCurrentRuntime(named name: String, type: String) throws {
    productName = name

    let manifestURL = projectURL("Package.swift")
    if !fileManager.fileExists(atPath: manifestURL.path) {
        let result = try ProcessRunner().run(
            executable: "/usr/bin/env",
            arguments: ["swift", "package", "init", "--name", name, "--type", type],
            workingDirectory: projectURL(),
            environment: SPMRuntime.current.environment,
            timeout: 120
        )
        guard result.status == 0 else {
            throw SPMCommandError.failure(
                "swift package init failed: \(result.standardError)",
                exitCode: result.status
            )
        }
    }

    try updateCreatedPackageManifest(at: manifestURL)
    try writeSwiftPackageIndexConfiguration()
    try header(options: OverwriteOptions(force: true))
    try generateMissingProjectFiles()
}

/// Updates a newly created package manifest to the supported tools version.
private static func updateCreatedPackageManifest(at manifestURL: URL) throws {
    do {
        let package = try String(contentsOf: manifestURL, encoding: .utf8)
        try packageBySettingToolsVersion(package).write(to: manifestURL, atomically: true, encoding: .utf8)
        printC("Set swift-tools-version to 6.0", color: CLIColors.green)
    } catch {
        throw SPMCommandError.failure("Failed to update Package.swift: \(error)", exitCode: 1)
    }
}

/// Writes Swift Package Index metadata for a newly created package.
private static func writeSwiftPackageIndexConfiguration() throws {
    let contents = """
    version: 1
    builder:
      configs:
        - documentation_targets: [\(productName)]
    """
    do {
        try contents.write(to: projectURL(".spi.yml"), atomically: true, encoding: .utf8)
    } catch {
        throw SPMCommandError.failure("Failed to write .spi.yml: \(error)", exitCode: 1)
    }
}

/// Generates standard repository files that are not already present.
private static func generateMissingProjectFiles() throws {
    if !fileManager.fileExists(atPath: projectURL("README.md").path) {
        try generateReadme()
    }

    if !fileManager.fileExists(atPath: projectURL("LICENCE.md").path) {
        try generateMITLicense()
    }

    if !fileManager.fileExists(atPath: projectURL(".editorconfig").path) {
        try generateEditorConfig()
    }

    if !fileManager.fileExists(atPath: projectURL(".gitignore").path) {
        try generateGitIgnore()
    }

    if !fileManager.fileExists(atPath: projectURL(".swiftlint.yml").path) {
        try generateSwiftLint()
    }
}
/// Replaces a package manifest's tools-version declaration with the supported baseline.
static func packageBySettingToolsVersion(_ package: String, version: String = "6.0") -> String {
    package
        .components(separatedBy: .newlines)
        .enumerated()
        .map { index, line in
            index == 0 ? "// swift-tools-version: \(version)" : line
        }
        .joined(separator: "\n")
}

/// Builds the package for platforms detected in Package.swift.
static func buildPackageForDetectedPlatforms(options: BuildOptions = BuildOptions()) throws {
    let name = try requiredProductName()
    if options.native {
        let result = try ProcessRunner().run(
            executable: "/usr/bin/env",
            arguments: ["swift", "build", "-c", options.configuration],
            workingDirectory: projectURL(),
            timeout: 300
        )
        guard result.status == 0 else {
            throw SPMCommandError.failure("Native build failed: \(result.standardError)", exitCode: result.status)
        }
        printC("Native \(options.configuration) build successful", color: CLIColors.green)
        return
    }

    let package: String
    do {
        package = try String(contentsOf: projectURL("Package.swift"), encoding: .utf8)
    } catch {
        throw SPMCommandError.failure("Failed to read Package.swift: \(error)", exitCode: 2)
    }
    let platforms = options.platforms.isEmpty ? detectedBuildPlatforms(in: package) : options.platforms

    printC("Build \(name) for \(platforms.joined(separator: ", "))...")

    let failures = try platforms.enumerated().reduce(into: 0) { count, item in
        if try !buildPackage(
            platform: item.element,
            number: item.offset,
            total: platforms.count,
            options: options
        ) {
            count += 1
        }
    }

    guard failures == 0 else {
        throw SPMCommandError.failure("Failed to build for \(failures) platform(s).", exitCode: 1)
    }

    printC("Build for all platforms successful", color: CLIColors.green)
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
static func buildPackage(platform: String, number: Int, total: Int, options: BuildOptions) throws -> Bool {
    let current = number + 1
    let progress = progressBar(current: current, total: total)
    let message = "\(progress) Building \(productName) for \(platform)"

    let arguments = [
        "xcrun",
        "xcodebuild",
        "clean",
        "build",
        "-quiet",
        "-configuration", options.configuration.capitalized,
        "-scheme", options.scheme ?? productName,
        "-destination", options.destination ?? "generic/platform=\(platform)"
    ]
    printC(message)
    let result = try ProcessRunner().run(
        executable: "/usr/bin/env",
        arguments: arguments,
        workingDirectory: projectURL(),
        timeout: 600
    )
    let terminationStatus = result.status

    if terminationStatus == 0 {
        printC("\(progress) Build for \(platform) successful", color: CLIColors.green)
        return true
    }

    printC("\(progress) Failed to build for \(platform)", color: CLIColors.red)
    return false
}

/// Runs `swift test` with any forwarded test arguments.
static func testSwiftPackage(arguments: [String]) throws {
    let name = try requiredProductName()

    printC("Testing \(name)...")

    let result = try ProcessRunner().run(
        executable: "/usr/bin/env",
        arguments: ["swift", "test"] + arguments,
        workingDirectory: projectURL(),
        timeout: 600
    )
    guard result.status == 0 else {
        throw SPMCommandError.failure("Tests failed: \(result.standardError)", exitCode: result.status)
    }

    printC("Tests passed", color: CLIColors.green)
}

/// Builds static web documentation with DocC.
static func buildDocumentation(arguments: [String]) throws {
    _ = try requiredProductName()
    let options = try documentationOptions(from: arguments)
    let workingDirectory = projectURL()
    let scratchDirectory = workingDirectory
        .appendingPathComponent(".build", isDirectory: true)
        .appendingPathComponent("spm-documentation", isDirectory: true)
    let symbolGraphDirectory = scratchDirectory.appendingPathComponent("SymbolGraphs", isDirectory: true)
    let fallbackCatalog = scratchDirectory.appendingPathComponent("\(options.target).docc", isDirectory: true)
    let catalog = documentationCatalog(for: options.target) ?? fallbackCatalog

    try prepareDocumentationDirectories(
        scratchDirectory: scratchDirectory,
        symbolGraphDirectory: symbolGraphDirectory,
        fallbackCatalog: fallbackCatalog
    )
    try buildDocumentationSymbolGraphs(options: options, symbolGraphDirectory: symbolGraphDirectory)
    try convertDocumentation(
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
) throws {
    do {
        try fileManager.removeItem(at: scratchDirectory)
    } catch CocoaError.fileNoSuchFile {
    } catch {
        throw SPMCommandError.failure(
            "Failed to clear documentation scratch directory: \(error)",
            exitCode: 3
        )
    }

    do {
        try fileManager.createDirectory(at: symbolGraphDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: fallbackCatalog, withIntermediateDirectories: true)
    } catch {
        throw SPMCommandError.failure("Failed to prepare documentation directories: \(error)", exitCode: 3)
    }
}

/// Builds symbol graphs for DocC conversion.
static func buildDocumentationSymbolGraphs(
    options: DocumentationOptions,
    symbolGraphDirectory: URL
) throws {
    printC("Generating symbol graphs for \(options.target)...")
    let symbolGraphStatus = try runProcess(
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
        throw SPMCommandError.failure("Failed to generate symbol graphs.", exitCode: symbolGraphStatus)
    }
}

/// Converts symbol graphs and the documentation catalog into static web documentation.
static func convertDocumentation(
    options: DocumentationOptions,
    catalog: URL,
    symbolGraphDirectory: URL
) throws {
    printC("Building static documentation in \(options.outputPath)...")
    let doccStatus = try runProcess(
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
        throw SPMCommandError.failure("Failed to build documentation.", exitCode: doccStatus)
    }

    printC("Documentation built at \(options.outputPath)", color: CLIColors.green)
}

}
