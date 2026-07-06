//
//  ParseXcodePackageSemanticVersion.swift
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
/// Parses a Git tag or ref into a semantic version value.
static func parseXcodePackageSemanticVersion(_ tag: String) -> XcodePackageSemanticVersion? {
    let clean = tag
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "refs/tags/", with: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

    let parts = clean.split(separator: ".")
    guard parts.count >= 2 else { return nil }

    let numericParts = parts.prefix(3).map { part -> Int? in
        let digits = part.prefix { $0.isNumber }
        return Int(digits)
    }

    guard
        let major = numericParts[safe: 0] ?? nil,
        let minor = numericParts[safe: 1] ?? nil
    else {
        return nil
    }

    let patch = (numericParts[safe: 2] ?? nil) ?? 0
    return XcodePackageSemanticVersion(major: major, minor: minor, patch: patch, original: clean)
}
}
