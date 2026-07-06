//
//  SwiftPackageName.swift
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
/// Derives a package name from a Swift package URL.
static func swiftPackageName(from packageURL: String) -> String {
    let trimmed = packageURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let lastComponent = trimmed.split(separator: "/").last.map(String.init) ?? "Package"
    return lastComponent.hasSuffix(".git") ? String(lastComponent.dropLast(4)) : lastComponent
}
}
