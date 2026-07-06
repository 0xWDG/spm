//
//  CLI.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Colored terminal output
public struct CLIColors {
    /// ANSI escape code for red text
    public static let red = "\u{001B}[0;31m"
    /// ANSI escape code for green text
    public static let green = "\u{001B}[0;32m"
    /// ANSI escape code for yellow text
    public static let yellow = "\u{001B}[0;33m"
    /// ANSI escape code for orange text
    public static let orange = "\u{001B}[0;38;5;208m"
    /// ANSI escape code for blue text
    public static let blue = "\u{001B}[0;34m"
    /// ANSI escape code for cyan text
    public static let cyan = "\u{001B}[0;36m"
    /// ANSI escape code for white text
    public static let white = "\u{001B}[0;37m"
    /// ANSI escape code to reset text color
    public static let reset = "\u{001B}[0;0m"
    /// ANSI escape code to clear text
    public static let clear = "\u{001B}[0;0m"
    /// ANSI escape code for bold text
    public static let bold = "\u{001B}[1m"
    /// ANSI escape code for underlined text
    public static let underline = "\u{001B}[4m"
}

/// Prints the command-line usage and available commands.
public func printUsage() {
    let executable = CommandLine.arguments[0].components(separatedBy: "/").last ?? "spm"

    print("spm - Swift Package Manager Manager (v0.0.2)\n")
    print("Usage: \(executable) <command>\n")

    print("Commands:")
    print(" Create <package name> - Create a package in current directory")
    print(" header - Update the header for all .swift files in the current directory")
    print(" readme - Generate a README.md file for the package (overwrites existing file)")
    print(" licence - Generate a LICENCE.md file for the package (overwrites existing file)")
    print(" build - Build the package for all platforms")
    print(" documentation [options] - Build web documentation with DocC")
    print(" test [swift-test-options] - Test the Swift package project")
    print(" --test [swift-test-options] - Test the Swift package project")
    print(" install <package url|owner/repo|repo> - Install a Swift package into the Xcode project in the current directory")
    print(" config init - Create local .spm/config.json")
    print(" config global init - Create global ~/.config/spm/config.json")
    print(" config show - Print the merged configuration")
    print(" config set <key> <value> - Set a local configuration value")
    print(" config global set <key> <value> - Set a global configuration value")
    print("\nDocumentation options:")
    print(" --target <target> - Documentation target name (defaults to package name)")
    print(" --output-path <path> - Output directory (defaults to docs)")
    print(" --hosting-base-path <path> - Static hosting base path (defaults to /<package name>)")
}

/// Prints colored terminal output and flushes when writing without a newline.
public func printC(_ text: String, terminator: String = "\n", color: String = CLIColors.reset) {
    if terminator == "\n" {
        print("\(color)\(text)                        \(CLIColors.reset)")
    } else {
        print("\(color)\(text)\(CLIColors.reset)", terminator: terminator)
        fflush(stdout)
    }
}
