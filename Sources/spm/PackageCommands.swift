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

/// Creates and bootstraps a Swift package with the project defaults.
public func createPackage(named name: String) {
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
public func buildPackageForDetectedPlatforms() {
    if !fileManager.fileExists(atPath: "Package.swift") {
        printC("Package.swift not found", color: CLIColors.red)
        exit(2)
    }

    let package = (try? String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8)) ?? ""
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
    }

    if package.contains(".linux") {
        printC("Linux is not supported, skipped", color: CLIColors.orange)
    }

    if package.contains(".android") {
        printC("Android is not supported, skipped", color: CLIColors.orange)
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
}

/// Runs `swift test` with any forwarded test arguments.
public func testSwiftPackage(arguments: [String]) {
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
public func buildDocumentation(arguments: [String]) {
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
public func compileExecutable() {
    let sourceDirectory = URL(fileURLWithPath: "Sources/spm")
    guard let sources = try? fileManager.contentsOfDirectory(
        at: sourceDirectory,
        includingPropertiesForKeys: nil
    ).filter({ $0.pathExtension == "swift" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
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

/// Parsed options for the documentation command.
public struct DocumentationOptions {
    public let target: String
    public let outputPath: String
    public let hostingBasePath: String

    /// Creates documentation build options.
    public init(target: String, outputPath: String, hostingBasePath: String) {
        self.target = target
        self.outputPath = outputPath
        self.hostingBasePath = hostingBasePath
    }
}

/// Parses documentation command arguments into build options.
public func documentationOptions(from arguments: [String]) -> DocumentationOptions {
    var target = productName
    var outputPath = "docs"
    var hostingBasePath = "/\(productName)"
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--target":
            target = documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        case "--output-path", "--output", "-o":
            outputPath = documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        case "--hosting-base-path", "--base-path":
            hostingBasePath = documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        default:
            printC("Unknown documentation option: \(argument)", color: CLIColors.red)
            print("Usage: \(CommandLine.arguments[0]) documentation [--target <target>] [--output-path <path>] [--hosting-base-path <path>]")
            exit(1)
        }
    }

    return DocumentationOptions(
        target: target,
        outputPath: outputPath,
        hostingBasePath: hostingBasePath
    )
}

/// Returns the value that follows a documentation command option.
public func documentationOptionValue(_ arguments: [String], at index: Int, option: String) -> String {
    let valueIndex = index + 1
    guard valueIndex < arguments.count else {
        printC("Missing value for \(option)", color: CLIColors.red)
        exit(1)
    }

    return arguments[valueIndex]
}

/// Finds a documentation catalog for a target if the package provides one.
public func documentationCatalog(for target: String) -> URL? {
    let candidates = [
        URL(fileURLWithPath: "Sources").appendingPathComponent(target).appendingPathComponent("\(target).docc"),
        URL(fileURLWithPath: "Sources").appendingPathComponent(target).appendingPathComponent("Documentation.docc"),
        URL(fileURLWithPath: "Documentation.docc"),
        URL(fileURLWithPath: "\(target).docc")
    ]

    return candidates.first { fileManager.fileExists(atPath: $0.path) }
}

/// Runs a process attached to the current standard streams and returns its exit status.
public func runProcess(launchPath: String, arguments: [String]) -> Int32 {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus
}
