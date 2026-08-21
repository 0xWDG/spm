//
//  SPMOutput.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Global output options accepted by every command.
public struct SPMOutputOptions: Equatable, Sendable {
    /// Emits newline-delimited JSON records.
    public let json: Bool
    /// Suppresses non-error informational output.
    public let quiet: Bool
    /// Disables ANSI color output.
    public let noColor: Bool

    /// Creates output options.
    public init(json: Bool = false, quiet: Bool = false, noColor: Bool = false) {
        self.json = json
        self.quiet = quiet
        self.noColor = noColor
    }
}

/// Structured output record emitted in JSON mode.
public struct SPMOutputRecord: Codable, Sendable {
    /// Severity or semantic category.
    public let level: String
    /// Human-readable event message.
    public let message: String

    /// Creates a structured output record.
    public init(level: String, message: String) {
        self.level = level
        self.message = message
    }
}

public extension SPM {
    /// Output behavior for the active command.
    nonisolated(unsafe) static var outputOptions = SPMOutputOptions()

    /// Extracts global output flags while preserving command-specific arguments.
    static func extractOutputOptions(from arguments: [String]) -> (arguments: [String], options: SPMOutputOptions) {
        guard let executable = arguments.first else {
            return (arguments, SPMOutputOptions())
        }

        let flags = Set(arguments.dropFirst())
        let options = SPMOutputOptions(
            json: flags.contains("--json"),
            quiet: flags.contains("--quiet"),
            noColor: flags.contains("--no-color")
        )
        let filtered = [executable] + arguments.dropFirst().filter {
            !["--json", "--quiet", "--no-color"].contains($0)
        }
        return (filtered, options)
    }

    /// Emits one message according to the active output policy.
    static func emit(_ message: String, level: String = "info", color: String = CLIColors.reset) {
        guard !outputOptions.quiet || level == "error" else { return }

        if outputOptions.json {
            let record = SPMOutputRecord(level: level, message: message)
            if let data = try? JSONEncoder().encode(record), let json = String(data: data, encoding: .utf8) {
                print(json)
            }
            return
        }

        let useColor = !outputOptions.noColor && shouldUseHelpColors()
        print(useColor ? "\(color)\(message)\(CLIColors.reset)" : message)
    }
}
