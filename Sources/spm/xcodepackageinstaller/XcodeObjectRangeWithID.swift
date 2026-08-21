//
//  XcodeObjectRangeWithID.swift
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
/// Finds the full Xcode object range for a specific object identifier.
static func xcodeObjectRange(withID id: String, in text: String) -> Range<String.Index>? {
    guard let idRange = text.range(of: "\t\t\(id)") ?? text.range(of: "\n\t\t\(id)") else {
        return nil
    }

    guard let assignmentRange = text.range(of: "= {", range: idRange.upperBound..<text.endIndex) else {
        return nil
    }

    var index = assignmentRange.lowerBound
    var depth = 0
    while index < text.endIndex {
        let character = text[index]
        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                guard let semicolon = text[index...].firstIndex(of: ";") else { return nil }
                return idRange.lowerBound..<text.index(after: semicolon)
            }
        }
        index = text.index(after: index)
    }

    return nil
}
}
