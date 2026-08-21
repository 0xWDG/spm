//
//  SPMCommandError.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Errors presented by the command-line executable.
public enum SPMCommandError: Error, CustomStringConvertible {
    /// Help requested implicitly by running the executable without a command.
    case help(String)
    /// Command arguments were missing or invalid.
    case usage(String)
    /// An operation could not be completed.
    case failure(String, exitCode: Int32)
    /// A command refused to replace an existing file.
    case fileExists(String)

    /// Exit status appropriate for this error.
    public var exitCode: Int32 {
        switch self {
        case .help, .usage, .fileExists:
            return 2
        case .failure(_, let exitCode):
            return exitCode == 0 ? 1 : exitCode
        }
    }

    /// Human-readable error text.
    public var description: String {
        switch self {
        case .help(let executable):
            return SPM.usage(executable: executable)
        case .usage(let message), .failure(let message, _):
            return message
        case .fileExists(let path):
            return "Refusing to overwrite \(path). Pass --force to replace it or --dry-run to preview the change."
        }
    }

    /// Error text formatted for its output destination.
    public func formattedDescription(colorEnabled: Bool) -> String {
        switch self {
        case .help(let executable):
            return SPM.helpText(executable: executable, colorEnabled: colorEnabled)
        default:
            return description
        }
    }
}
