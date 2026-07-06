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

private final class CLIProgressState {
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

public extension spm {
/// Prints the command-line usage and available commands.
static func printUsage() {
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
    print(" install <package url|owner/repo|repo> - Install a Swift package into the current Xcode project")
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
static func printC(_ text: String, terminator: String = "\n", color: String = CLIColors.reset) {
    if terminator == "\n" {
        print("\(color)\(text)                        \(CLIColors.reset)")
    } else {
        print("\(color)\(text)\(CLIColors.reset)", terminator: terminator)
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
static func runProcessWithSpinner(_ process: Process, message: String) -> Int32 {
    let frames = ["-", "\\", "|", "/"]
    let state = CLIProgressState()

    process.launch()

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
