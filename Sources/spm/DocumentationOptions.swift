//
//  DocumentationOptions.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Parsed options for the documentation command.
public struct DocumentationOptions {
    /// Package target to document.
    public let target: String
    /// Static documentation output path.
    public let outputPath: String
    /// Base path used when transforming documentation for static hosting.
    public let hostingBasePath: String

    /// Creates documentation build options.
    public init(target: String, outputPath: String, hostingBasePath: String) {
        self.target = target
        self.outputPath = outputPath
        self.hostingBasePath = hostingBasePath
    }
}

public extension spm {
/// Parses documentation command arguments into build options.
static func documentationOptions(from arguments: [String]) -> DocumentationOptions {
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
            print(documentationUsage)
            exit(1)
        }
    }

    return DocumentationOptions(
        target: target,
        outputPath: outputPath,
        hostingBasePath: hostingBasePath
    )
}

/// Usage text for the documentation command.
static var documentationUsage: String {
    """
    Usage: \(CommandLine.arguments[0]) documentation \
    [--target <target>] [--output-path <path>] [--hosting-base-path <path>]
    """
}

/// Returns the value that follows a documentation command option.
static func documentationOptionValue(_ arguments: [String], at index: Int, option: String) -> String {
    let valueIndex = index + 1
    guard valueIndex < arguments.count else {
        printC("Missing value for \(option)", color: CLIColors.red)
        exit(1)
    }

    return arguments[valueIndex]
}

/// Finds a documentation catalog for a target if the package provides one.
static func documentationCatalog(for target: String) -> URL? {
    let sourceTarget = URL(fileURLWithPath: "Sources").appendingPathComponent(target)
    let candidates = [
        sourceTarget.appendingPathComponent("\(target).docc"),
        sourceTarget.appendingPathComponent("Documentation.docc"),
        URL(fileURLWithPath: "Documentation.docc"),
        URL(fileURLWithPath: "\(target).docc")
    ]

    return candidates.first { fileManager.fileExists(atPath: $0.path) }
}

/// Runs a process attached to the current standard streams and returns its exit status.
static func runProcess(launchPath: String, arguments: [String]) -> Int32 {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus
}
}
