//
//  XcodeObjectComment.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Extracts the first inline Xcode object comment from an object block.
public func xcodeObjectComment(from object: String) -> String? {
    guard let start = object.range(of: "/*"),
          let end = object.range(of: "*/", range: start.upperBound..<object.endIndex)
    else {
        return nil
    }

    return String(object[start.upperBound..<end.lowerBound])
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
