//
//  DefaultBranch.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Reads the default branch for a remote package URL.
public func defaultBranch(forPackageURL packageURL: String) -> String? {
    guard let output = try? runXcodePackageInstallerCommand("/usr/bin/git", ["ls-remote", "--symref", packageURL, "HEAD"]) else {
        return nil
    }

    for line in output.split(separator: "\n") {
        guard line.hasPrefix("ref: refs/heads/") else { continue }
        let pieces = line.split(separator: "\t")
        guard let ref = pieces.first else { continue }
        return ref
            .replacingOccurrences(of: "ref: refs/heads/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return nil
}
