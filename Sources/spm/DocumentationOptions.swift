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

public extension SPM {
/// Parses documentation command arguments into build options.
static func documentationOptions(from arguments: [String]) throws -> DocumentationOptions {
    var target = try requiredProductName()
    var outputPath = "docs"
    var hostingBasePath = "/\(productName)"
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--target":
            target = try documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        case "--output-path", "--output", "-o":
            outputPath = try documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        case "--hosting-base-path", "--base-path":
            hostingBasePath = try documentationOptionValue(arguments, at: index, option: argument)
            index += 2
        default:
            throw SPMCommandError.usage("Unknown documentation option: \(argument)\n\(documentationUsage)")
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
static func documentationOptionValue(_ arguments: [String], at index: Int, option: String) throws -> String {
    let valueIndex = index + 1
    guard valueIndex < arguments.count else {
        throw SPMCommandError.usage("Missing value for \(option)\n\(documentationUsage)")
    }

    return arguments[valueIndex]
}

/// Finds a documentation catalog for a target if the package provides one.
static func documentationCatalog(for target: String) -> URL? {
    let sourceTarget = projectURL("Sources").appendingPathComponent(target)
    let candidates = [
        sourceTarget.appendingPathComponent("\(target).docc"),
        sourceTarget.appendingPathComponent("Documentation.docc"),
        projectURL("Documentation.docc"),
        projectURL("\(target).docc")
    ]

    return candidates.first { fileManager.fileExists(atPath: $0.path) }
}

/// Runs a process attached to the current standard streams and returns its exit status.
static func runProcess(launchPath: String, arguments: [String]) throws -> Int32 {
    let result = try ProcessRunner().run(
        executable: launchPath,
        arguments: arguments,
        workingDirectory: SPMRuntime.current.workingDirectory,
        timeout: 300
    )
    if !result.standardOutput.isEmpty && !outputOptions.quiet { print(result.standardOutput, terminator: "") }
    if !result.standardError.isEmpty { FileHandle.standardError.write(Data(result.standardError.utf8)) }
    return result.status
}
}
