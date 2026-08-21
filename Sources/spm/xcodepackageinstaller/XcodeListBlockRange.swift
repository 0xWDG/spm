//
//  XcodeListBlockRange.swift
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
/// Finds a named list block inside an Xcode project object.
static func xcodeListBlockRange(named name: String, in object: String) -> Range<String.Index>? {
    guard let start = object.range(of: "\(name) = (") else { return nil }
    return object.range(of: "\n\t\t\t);", range: start.upperBound..<object.endIndex)
        .map { start.lowerBound..<$0.upperBound }
}
}
