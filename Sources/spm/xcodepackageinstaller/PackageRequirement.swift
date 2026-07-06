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

public extension spm {
/// Chooses an Xcode package requirement from remote tags or the default branch.
static func packageRequirement(forPackageURL packageURL: String) -> XcodePackageRequirement {
    let arguments = ["ls-remote", "--tags", "--refs", packageURL]
    if let output = try? runXcodePackageInstallerCommand("/usr/bin/git", arguments) {
        let versions = output
            .split(separator: "\n")
            .compactMap { line -> XcodePackageSemanticVersion? in
                guard let ref = line.split(separator: "\t").last else { return nil }
                return parseXcodePackageSemanticVersion(String(ref))
            }

        if let latest = versions.max(by: isOlderXcodePackageSemanticVersion) {
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

/// Compares semantic versions by major, minor, and patch components.
static func isOlderXcodePackageSemanticVersion(
    lhs: XcodePackageSemanticVersion,
    rhs: XcodePackageSemanticVersion
) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    return lhs.patch < rhs.patch
}
}
