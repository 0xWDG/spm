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

public extension SPM {
/// Reads the default branch for a remote package URL.
static func defaultBranch(forPackageURL packageURL: String) -> String? {
    let arguments = ["ls-remote", "--symref", packageURL, "HEAD"]
    guard let output = try? runXcodePackageInstallerCommand("/usr/bin/git", arguments) else {
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
}
