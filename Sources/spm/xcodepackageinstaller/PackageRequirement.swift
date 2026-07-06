//
//  PackageRequirement.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Chooses an Xcode package requirement from remote tags or the default branch.
public func packageRequirement(forPackageURL packageURL: String) -> XcodePackageRequirement {
    if let output = try? runXcodePackageInstallerCommand("/usr/bin/git", ["ls-remote", "--tags", "--refs", packageURL]) {
        let versions = output
            .split(separator: "\n")
            .compactMap { line -> XcodePackageSemanticVersion? in
                guard let ref = line.split(separator: "\t").last else { return nil }
                return parseXcodePackageSemanticVersion(String(ref))
            }

        if let latest = versions.max() {
            return XcodePackageRequirement(lines: [
                "kind = upToNextMajorVersion;",
                "minimumVersion = \(latest.original);"
            ])
        }
    }

    let branch = defaultBranch(forPackageURL: packageURL) ?? "main"
    return XcodePackageRequirement(lines: [
        "branch = \(branch);",
        "kind = branch;"
    ])
}
