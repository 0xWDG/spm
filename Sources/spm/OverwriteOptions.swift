//
//  OverwriteOptions.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Controls whether a generator previews or replaces files.
public struct OverwriteOptions: Equatable {
    /// Allows an existing destination to be replaced.
    public let force: Bool
    /// Reports intended changes without writing them.
    public let dryRun: Bool
    /// Prints a text diff without writing changes.
    public let diff: Bool

    /// Creates generator overwrite options.
    public init(force: Bool = false, dryRun: Bool = false, diff: Bool = false) {
        self.force = force
        self.dryRun = dryRun
        self.diff = diff
    }
}

extension SPM {
    /// Parses common generator safety options.
    static func overwriteOptions(from arguments: [String]) throws -> OverwriteOptions {
        let supported = Set(["--force", "--dry-run", "--diff"])
        guard let unknown = arguments.first(where: { !supported.contains($0) }) else {
            return OverwriteOptions(
                force: arguments.contains("--force"),
                dryRun: arguments.contains("--dry-run"),
                diff: arguments.contains("--diff")
            )
        }

        throw SPMCommandError.usage("Unknown generator option: \(unknown). Use --force, --dry-run, or --diff.")
    }

    /// Writes generated content after applying overwrite safety rules.
    static func writeGeneratedFile(
        _ contents: String,
        to destination: URL,
        options: OverwriteOptions
    ) throws {
        let exists = fileManager.fileExists(atPath: destination.path)
        if exists && !options.force && !options.dryRun && !options.diff {
            throw SPMCommandError.fileExists(destination.path)
        }

        if options.diff {
            let original = (try? String(contentsOf: destination, encoding: .utf8)) ?? ""
            print(unifiedDiff(original: original, updated: contents, path: destination.lastPathComponent))
            return
        }

        if options.dryRun {
            let action = exists ? "Would replace" : "Would create"
            print("\(action) \(destination.path)")
            return
        }

        do {
            try contents.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            throw SPMCommandError.failure("Failed to write \(destination.path): \(error)", exitCode: 1)
        }
    }
}
