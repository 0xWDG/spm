//
//  PossibleSwiftPackageProductNames.swift
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
/// Returns likely product names for a package when the manifest cannot be inspected.
static func possibleSwiftPackageProductNames(from packageName: String) -> [String] {
    let withoutSwiftPrefix = packageName.hasPrefix("swift-")
        ? String(packageName.dropFirst("swift-".count))
        : packageName

    return Array(Set([
        packageName,
        withoutSwiftPrefix,
        pascalCase(packageName),
        pascalCase(withoutSwiftPrefix)
    ])).filter { !$0.isEmpty }
}

/// Converts a dashed or underscored package name into PascalCase.
static func pascalCase(_ value: String) -> String {
    let separators = CharacterSet(charactersIn: "-_")

    return value
        .components(separatedBy: separators)
        .filter { !$0.isEmpty }
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined()
}
}
