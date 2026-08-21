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
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private final class CLIProgressState: @unchecked Sendable {
    let lock = NSLock()
    var isRunning = true
}

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

public extension SPM {
/// Returns command-line usage and available commands.
static func usage(executable: String = "spm") -> String {
    let command = executable.components(separatedBy: "/").last ?? "spm"
    return """
    spm - Swift Package Manager Manager (v\(SPMVersion.current))

    Usage: \(command) [global options] <command> [options]

    Commands:
     create <name> [--type <type>] [--path <path>] - Create a Swift package
     header [options] - Update scoped Swift file headers
     readme|licence|editorconfig|gitignore|swiftlint [options] - Generate project files
     diff <generator> [options] - Preview a generator as a unified diff
     build [options] - Build with SwiftPM or for selected Apple platforms
     documentation [options] - Build web documentation with DocC
     test [swift-test-options] - Test the Swift package project
     install <package> [options] - Add and link a package in an Xcode project
     uninstall <package> [--dry-run] - Remove a package from an Xcode project
     executable [--force|--dry-run] - Compile a local ./spm executable
     config <action> - Show, initialize, validate, set, unset, or reset configuration
     completion <zsh|bash|fish> - Print shell completion setup
     doctor - Check the development environment and project
     version - Print the spm version
     help - Show this command reference

    Global options:
     --json - Emit machine-readable JSON output where supported
     --quiet - Suppress informational output
     --no-color - Disable ANSI colors
    """ + "\n\n" + optionUsage()
}

/// Returns detailed command-option usage.
private static func optionUsage() -> String {
    """
    Generator options:
     --force - Replace an existing destination
     --dry-run - Report intended changes without writing files
     --diff - Print a unified diff without writing files

    Header options:
     --include <path> - Limit changes to a path; repeatable
     --exclude <path> - Skip a path; repeatable

    Build options:
     --platform <name[,name]> - Build only selected declared Apple platforms
     --configuration <debug|release> - Select the build configuration
     --scheme <name> - Override the Xcode scheme
     --destination <value> - Override the Xcode destination
     --native - Use swift build instead of Xcode

    Install options:
     --target <name> - Link only to a target; repeatable
     --product <name> - Link only a product; repeatable
     --dry-run - Preview the Xcode project diff

    Configuration actions:
     config [global] init|show|validate|reset
     config [global] set <key> <value>
     config [global] unset <key>

    Documentation options:
     --target <target> - Documentation target name (defaults to package name)
     --output-path <path> - Output directory (defaults to docs)
     --hosting-base-path <path> - Static hosting base path (defaults to /<package name>)
    """
}

/// Returns help text with optional ANSI styling.
static func helpText(executable: String = "spm", colorEnabled: Bool) -> String {
    let plainText = usage(executable: executable)
    guard colorEnabled else {
        return plainText
    }

    return plainText
        .components(separatedBy: .newlines)
        .map(colorizedHelpLine)
        .joined(separator: "\n")
}

/// Returns whether help output should use ANSI colors.
static func shouldUseHelpColors(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    isTerminal: Bool = isatty(fileno(stdout)) != 0
) -> Bool {
    if outputOptions.noColor {
        return false
    }

    if environment["NO_COLOR"] != nil {
        return false
    }

    if let forceColor = environment["FORCE_COLOR"] {
        return forceColor != "0"
    }

    return isTerminal
}

/// Returns whether help written to standard error should use ANSI colors.
static func shouldUseHelpColorsForStandardError() -> Bool {
    shouldUseHelpColors(isTerminal: isatty(fileno(stderr)) != 0)
}

/// Prints the command-line usage and available commands.
static func printUsage(executable: String = "spm") {
    print(helpText(executable: executable, colorEnabled: shouldUseHelpColors()))
}

/// Adds ANSI styling to one semantic line of help output.
private static func colorizedHelpLine(_ line: String) -> String {
    if line.hasPrefix("spm - ") {
        return "\(CLIColors.bold)\(CLIColors.cyan)\(line)\(CLIColors.reset)"
    }

    if line.hasPrefix("Usage: ") {
        let value = String(line.dropFirst("Usage: ".count))
        let label = "\(CLIColors.bold)\(CLIColors.yellow)Usage:\(CLIColors.reset)"
        return "\(label) \(CLIColors.green)\(value)\(CLIColors.reset)"
    }

    if line.hasSuffix(":") {
        return "\(CLIColors.bold)\(CLIColors.blue)\(line)\(CLIColors.reset)"
    }

    guard line.hasPrefix(" "), let separator = line.range(of: " - ") else {
        return line
    }

    let specification = String(line[..<separator.lowerBound]).trimmingCharacters(in: .whitespaces)
    let description = String(line[separator.upperBound...])
    let components = specification.split(separator: " ", maxSplits: 1).map(String.init)
    let command = components[0]
    let arguments = components.count == 2 ? " \(components[1])" : ""
    return " \(CLIColors.green)\(command)\(CLIColors.cyan)\(arguments)\(CLIColors.reset) - \(description)"
}

/// Prints colored terminal output and flushes when writing without a newline.
static func printC(_ text: String, terminator: String = "\n", color: String = CLIColors.reset) {
    if terminator == "\n" {
        let level = color == CLIColors.red ? "error" : "info"
        emit(text, level: level, color: color)
    } else {
        guard !outputOptions.quiet && !outputOptions.json else { return }
        let useColor = !outputOptions.noColor && shouldUseHelpColors()
        print(useColor ? "\(color)\(text)\(CLIColors.reset)" : text, terminator: terminator)
        fflush(stdout)
    }
}

/// Returns a fixed-width progress bar for completed build platforms.
static func progressBar(current: Int, total: Int, width: Int = 20) -> String {
    guard total > 0 else {
        return "[\(String(repeating: "-", count: width))] 0/0"
    }

    let clampedCurrent = min(max(current, 0), total)
    let filledWidth = Int((Double(clampedCurrent) / Double(total)) * Double(width))
    let emptyWidth = width - filledWidth
    let filled = String(repeating: "#", count: filledWidth)
    let empty = String(repeating: "-", count: emptyWidth)
    return "[\(filled)\(empty)] \(clampedCurrent)/\(total)"
}

/// Runs a process while showing an indeterminate terminal spinner.
static func runProcessWithSpinner(_ process: Process, message: String) throws -> Int32 {
    let frames = ["-", "\\", "|", "/"]
    let state = CLIProgressState()

    do {
        try process.run()
    } catch {
        throw SPMCommandError.failure("Failed to launch process: \(error)", exitCode: 1)
    }

    DispatchQueue.global(qos: .userInitiated).async {
        var frameIndex = 0
        while true {
            state.lock.lock()
            let shouldContinue = state.isRunning
            state.lock.unlock()

            guard shouldContinue else {
                break
            }

            printC("\(frames[frameIndex % frames.count]) \(message)", terminator: "\r")
            frameIndex += 1
            Thread.sleep(forTimeInterval: 0.12)
        }
    }

    process.waitUntilExit()
    state.lock.lock()
    state.isRunning = false
    state.lock.unlock()
    clearCurrentLine()
    return process.terminationStatus
}

/// Clears the current terminal line.
static func clearCurrentLine(width: Int = 120) {
    print("\r\(String(repeating: " ", count: width))\r", terminator: "")
    fflush(stdout)
}
}
