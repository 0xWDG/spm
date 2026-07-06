//
//  NormalizedSwiftPackageURL.swift
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
/// Converts shorthand package input into a usable package URL.
static func normalizedSwiftPackageURL(from input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.contains("://") || trimmed.hasPrefix("git@") || trimmed.hasPrefix("ssh://") {
        return trimmed
    }

    if trimmed.hasPrefix("github.com/") {
        return "https://\(trimmed)"
    }

    let components = trimmed
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .split(separator: "/")

    if components.count == 2,
       !components[0].isEmpty,
       !components[1].isEmpty {
        return "https://github.com/\(components[0])/\(components[1])"
    }

    if components.count == 1,
       let repo = components.first,
       !repo.isEmpty {
        return "https://github.com/0xWDG/\(repo)"
    }

    return trimmed
}
}
