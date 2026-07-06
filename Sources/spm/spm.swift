//
//  spm.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

///  Entry point for the command-line application.
///  This function parses command-line arguments and executes the corresponding commands.
@main
public struct spm { // swiftlint:disable:this type_name
    /// Starts the command-line application.
    public static func main() {
        run(arguments: CommandLine.arguments)
    }
}

private extension spm {
    private typealias CommandHandler = ([String]) -> Void

    private static let commandHandlers: [String: CommandHandler] = [
        "create": runCreateCommand,
        "config": runConfigurationCommand,
        "header": { _ in header() },
        "readme": { _ in generateReadme() },
        "editorconfig": { _ in generateEditorConfig() },
        "licence": { _ in generateMITLicense() },
        "gitignore": { _ in generateGitIgnore() },
        "swiftlint": { _ in generateSwiftLint() },
        "build": { _ in buildPackageForDetectedPlatforms() },
        "--build": { _ in buildPackageForDetectedPlatforms() },
        "-b": { _ in buildPackageForDetectedPlatforms() },
        "documentation": runDocumentationCommand,
        "docs": runDocumentationCommand,
        "docc": runDocumentationCommand,
        "test": runTestCommand,
        "--test": runTestCommand,
        "-t": runTestCommand,
        "install": runInstallCommand,
        "package-install": runInstallCommand,
        "xcode-install": runInstallCommand,
        "executable": { _ in compileExecutable() }
    ]

    private static func run(arguments: [String]) {
        guard arguments.count >= 2 else {
            printUsage()
            exit(1)
        }

        guard let handler = commandHandlers[arguments[1]] else {
            printUsage()
            exit(1)
        }

        handler(arguments)
    }

    private static func runCreateCommand(arguments: [String]) {
        guard arguments.count >= 3 else {
            print("Usage: \(arguments[0]) create <package name>")
            exit(1)
        }

        createPackage(named: arguments[2])
    }

    private static func runDocumentationCommand(arguments: [String]) {
        buildDocumentation(arguments: Array(arguments.dropFirst(2)))
    }

    private static func runTestCommand(arguments: [String]) {
        testSwiftPackage(arguments: Array(arguments.dropFirst(2)))
    }

    private static func runInstallCommand(arguments: [String]) {
        let command = arguments[1]
        guard arguments.count == 3 else {
            print("Usage: \(arguments[0]) \(command) <swift-package-url|owner/repo|repo>")
            exit(1)
        }

        do {
            try installSwiftPackageInXcodeProject(packageURL: arguments[2])
            exit(0)
        } catch {
            printC("Error: \(error)", color: CLIColors.red)
            exit(1)
        }
    }
}

public extension spm {
    /// Routes configuration subcommands to local or global configuration operations.
    static func runConfigurationCommand(arguments: [String]) {
        guard arguments.count >= 3 else {
            printUsage()
            exit(1)
        }

        if arguments[2] == "show" {
            showConfiguration()
            return
        }

        if arguments[2] == "init" {
            initializeConfiguration(scope: .local)
            return
        }

        if arguments[2] == "set" {
            guard arguments.count >= 5 else {
                print("Usage: \(arguments[0]) config set <key> <value>")
                exit(1)
            }

            setConfigurationValue(
                key: arguments[3],
                value: Array(arguments.dropFirst(4)).joined(separator: " "),
                scope: .local
            )
            return
        }

        if arguments[2] == "global" {
            guard arguments.count >= 4 else {
                printUsage()
                exit(1)
            }

            if arguments[3] == "init" {
                initializeConfiguration(scope: .global)
                return
            }

            if arguments[3] == "set" {
                guard arguments.count >= 6 else {
                    print("Usage: \(arguments[0]) config global set <key> <value>")
                    exit(1)
                }

                setConfigurationValue(
                    key: arguments[4],
                    value: Array(arguments.dropFirst(5)).joined(separator: " "),
                    scope: .global
                )
                return
            }
        }

        printUsage()
        exit(1)
    }
}
