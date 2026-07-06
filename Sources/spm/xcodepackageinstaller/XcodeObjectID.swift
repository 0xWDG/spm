//
//  XcodeObjectID.swift
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
/// Extracts the object identifier from an Xcode project object block.
static func xcodeObjectID(from object: String) -> String? {
    object.split(separator: "=", maxSplits: 1).first?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .split(separator: " ")
        .first
        .map(String.init)
}
}
