//
//  FileTransaction.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// One file replacement in an atomic command transaction.
public struct FileChange: Sendable {
    /// Destination file URL.
    public let url: URL
    /// Replacement bytes.
    public let data: Data

    /// Creates a file replacement.
    public init(url: URL, data: Data) {
        self.url = url
        self.data = data
    }
}

public extension SPM {
    /// Applies file changes and restores original contents if any write fails.
    @discardableResult
    static func applyFileTransaction(_ changes: [FileChange], createBackups: Bool = false) throws -> [URL] {
        let originals = try changes.map { change -> (URL, Data?) in
            let data = fileManager.fileExists(atPath: change.url.path) ? try Data(contentsOf: change.url) : nil
            return (change.url, data)
        }
        var backups: [URL] = []

        do {
            for (change, original) in zip(changes, originals) {
                if createBackups, let originalData = original.1 {
                    let backup = change.url.deletingLastPathComponent()
                        .appendingPathComponent(
                            "\(change.url.lastPathComponent).backup-\(Int(Date().timeIntervalSince1970))"
                        )
                    try originalData.write(to: backup, options: .atomic)
                    backups.append(backup)
                }
                try change.data.write(to: change.url, options: .atomic)
            }
        } catch {
            for (url, data) in originals {
                if let data {
                    try? data.write(to: url, options: .atomic)
                } else {
                    try? fileManager.removeItem(at: url)
                }
            }
            throw SPMCommandError.failure("File transaction failed and was rolled back: \(error)", exitCode: 1)
        }

        return backups
    }
}
