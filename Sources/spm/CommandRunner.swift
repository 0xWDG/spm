//
//  CommandRunner.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Namespace for reusable package-management operations.
public enum SPM {
    private typealias CommandHandler = @Sendable ([String]) throws -> Void

    private static let commandHandlers: [String: CommandHandler] = [
        "create": runCreateCommand,
        "config": runConfigurationCommand,
        "header": { try header(commandOptions: headerCommandOptions(from: Array($0.dropFirst(2)))) },
        "readme": { try generateReadme(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "editorconfig": { try generateEditorConfig(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "licence": { try generateMITLicense(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "gitignore": { try generateGitIgnore(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "swiftlint": { try generateSwiftLint(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "build": runBuildCommand,
        "--build": runBuildCommand,
        "-b": runBuildCommand,
        "documentation": runDocumentationCommand,
        "docs": runDocumentationCommand,
        "docc": runDocumentationCommand,
        "test": runTestCommand,
        "--test": runTestCommand,
        "-t": runTestCommand,
        "install": runInstallCommand,
        "package-install": runInstallCommand,
        "xcode-install": runInstallCommand,
        "uninstall": runUninstallCommand,
        "diff": runDiffCommand,
        "doctor": { _ in try doctor() },
        "completion": runCompletionCommand,
        "version": { _ in printVersion() },
        "--version": { _ in printVersion() },
        "-v": { _ in printVersion() },
        "executable": { try compileExecutable(options: overwriteOptions(from: Array($0.dropFirst(2)))) },
        "help": { printUsage(executable: $0[0]) },
        "--help": { printUsage(executable: $0[0]) },
        "-h": { printUsage(executable: $0[0]) }
    ]

    /// Executes one command without terminating the current process.
    public static func run(arguments originalArguments: [String]) throws {
        let parsed = extractOutputOptions(from: originalArguments)
        outputOptions = parsed.options
        let arguments = parsed.arguments
        let executable = arguments.first ?? "spm"
        guard arguments.count >= 2 else {
            throw SPMCommandError.help(executable)
        }

        guard let handler = commandHandlers[arguments[1]] else {
            throw SPMCommandError.usage("Unknown command: \(arguments[1])\n\n\(usage(executable: executable))")
        }

        try handler(arguments)
    }
}

private extension SPM {
    static func runCreateCommand(arguments: [String]) throws {
        guard arguments.count >= 3 else {
            throw SPMCommandError.usage(
                "Usage: \(arguments[0]) create <package name> [--type <type>] [--path <path>]"
            )
        }
        var type = "library"
        var path = "."
        var index = 3
        while index < arguments.count {
            switch arguments[index] {
            case "--type": type = try optionValue(arguments, index: &index, option: "--type")
            case "--path": path = try optionValue(arguments, index: &index, option: "--path")
            default: throw SPMCommandError.usage("Unknown create option: \(arguments[index])")
            }
        }
        try createPackage(options: PackageCreationOptions(name: arguments[2], type: type, path: path))
    }

    static func runBuildCommand(arguments: [String]) throws {
        try buildPackageForDetectedPlatforms(options: buildOptions(from: Array(arguments.dropFirst(2))))
    }

    static func runDocumentationCommand(arguments: [String]) throws {
        try buildDocumentation(arguments: Array(arguments.dropFirst(2)))
    }

    static func runTestCommand(arguments: [String]) throws {
        try testSwiftPackage(arguments: Array(arguments.dropFirst(2)))
    }

    static func runInstallCommand(arguments: [String]) throws {
        let command = arguments[1]
        guard arguments.count >= 3 else {
            throw SPMCommandError.usage(
                "Usage: \(arguments[0]) \(command) <package> [--target <name>] [--product <name>] [--dry-run]"
            )
        }

        do {
            try installSwiftPackageInXcodeProject(
                packageURL: arguments[2],
                options: try packageInstallOptions(from: Array(arguments.dropFirst(3)))
            )
        } catch let error as SPMCommandError {
            throw error
        } catch {
            throw SPMCommandError.failure("Failed to install package: \(error)", exitCode: 1)
        }
    }

    static func runUninstallCommand(arguments: [String]) throws {
        guard arguments.count >= 3 else {
            throw SPMCommandError.usage("Usage: \(arguments[0]) uninstall <package> [--dry-run]")
        }
        let options = Array(arguments.dropFirst(3))
        guard options.allSatisfy({ $0 == "--dry-run" }) else {
            throw SPMCommandError.usage("Unknown uninstall option.")
        }
        try uninstallSwiftPackageFromXcodeProject(
            packageInput: arguments[2],
            dryRun: options.contains("--dry-run")
        )
    }

    static func runCompletionCommand(arguments: [String]) throws {
        guard arguments.count == 3 else {
            throw SPMCommandError.usage("Usage: \(arguments[0]) completion <zsh|bash|fish>")
        }
        try generateCompletion(for: arguments[2])
    }

    static func runDiffCommand(arguments: [String]) throws {
        guard arguments.count >= 3 else {
            throw SPMCommandError.usage("Usage: \(arguments[0]) diff <generator> [generator options]")
        }
        let options = Array(arguments.dropFirst(3)) + ["--diff"]
        switch arguments[2] {
        case "header": try header(commandOptions: headerCommandOptions(from: options))
        case "readme": try generateReadme(options: overwriteOptions(from: options))
        case "licence": try generateMITLicense(options: overwriteOptions(from: options))
        case "editorconfig": try generateEditorConfig(options: overwriteOptions(from: options))
        case "gitignore": try generateGitIgnore(options: overwriteOptions(from: options))
        case "swiftlint": try generateSwiftLint(options: overwriteOptions(from: options))
        default: throw SPMCommandError.usage("Unsupported diff generator: \(arguments[2])")
        }
    }

    static func packageInstallOptions(from arguments: [String]) throws -> PackageInstallOptions {
        var targets: [String] = []
        var products: [String] = []
        var dryRun = false
        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--target": targets.append(try optionValue(arguments, index: &index, option: "--target"))
            case "--product": products.append(try optionValue(arguments, index: &index, option: "--product"))
            case "--dry-run": dryRun = true; index += 1
            default: throw SPMCommandError.usage("Unknown install option: \(arguments[index])")
            }
        }
        return PackageInstallOptions(targets: targets, products: products, dryRun: dryRun)
    }

    static func printVersion() {
        if outputOptions.json {
            print("{\"version\":\"\(SPMVersion.current)\"}")
        } else if !outputOptions.quiet {
            print("spm \(SPMVersion.current)")
        }
    }

    static func runConfigurationCommand(arguments: [String]) throws {
        guard arguments.count >= 3 else {
            throw SPMCommandError.usage(usage(executable: arguments[0]))
        }

        var values = Array(arguments.dropFirst(2))
        let scope: ConfigurationScope
        if values.first == "global" {
            scope = .global
            values.removeFirst()
        } else {
            scope = .local
        }
        try runConfigurationCommand(values: values, scope: scope, executable: arguments[0])
    }

    static func runConfigurationCommand(
        values: [String],
        scope: ConfigurationScope,
        executable: String
    ) throws {
        switch values {
        case ["show"]:
            print(try configurationJSON())
        case ["init"]:
            try initializeConfiguration(scope: scope)
        case ["validate"]:
            try validateConfiguration()
        case ["reset"]:
            try resetConfiguration(scope: scope)
        case let values where values.count == 2 && values[0] == "unset":
            try unsetConfigurationValue(key: values[1], scope: scope)
        case let values where values.count >= 3 && values[0] == "set":
            try setConfigurationValue(
                key: values[1],
                value: values.dropFirst(2).joined(separator: " "),
                scope: scope
            )
        default:
            throw SPMCommandError.usage(usage(executable: executable))
        }
    }
}
