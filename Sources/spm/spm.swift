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
        guard CommandLine.arguments.count >= 2 else {
            printUsage()
            exit(1)
        }

        let command = CommandLine.arguments[1]

        switch command {
        case "create":
            if CommandLine.arguments.count < 3 {
                print("Usage: \(CommandLine.arguments[0]) create <package name>")
                exit(1)
            }
            createPackage(named: CommandLine.arguments[2])
        case "config":
            runConfigurationCommand(arguments: CommandLine.arguments)
        case "header":
            header()
        case "readme":
            generateReadme()
        case "editorconfig":
            generateEditorConfig()
        case "licence":
            generateMITLicense()
        case "gitignore":
            generateGitIgnore()
        case "swiftlint":
            generateSwiftLint()
        case "build", "--build", "-b":
            buildPackageForDetectedPlatforms()
        case "documentation", "docs", "docc":
            buildDocumentation(arguments: Array(CommandLine.arguments.dropFirst(2)))
        case "test", "--test", "-t":
            testSwiftPackage(arguments: Array(CommandLine.arguments.dropFirst(2)))
        case "install", "package-install", "xcode-install":
            guard CommandLine.arguments.count == 3 else {
                print("Usage: \(CommandLine.arguments[0]) \(command) <swift-package-url|owner/repo|repo>")
                exit(1)
            }

            do {
                try installSwiftPackageInXcodeProject(packageURL: CommandLine.arguments[2])
                exit(0)
            } catch {
                printC("Error: \(error)", color: CLIColors.red)
                exit(1)
            }

        case "executable":
            compileExecutable()
        default:
            printUsage()
            exit(1)
        }
    }

    /// Routes configuration subcommands to local or global configuration operations.
    public static func runConfigurationCommand(arguments: [String]) {
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
