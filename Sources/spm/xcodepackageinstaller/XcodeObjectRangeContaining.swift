//
//  XcodeObjectRangeContaining.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Finds the full Xcode object range containing a marker.
public func xcodeObjectRange(containing marker: String, in text: String) -> Range<String.Index>? {
    guard let markerRange = text.range(of: marker) else { return nil }

    var searchStart = text.startIndex
    var objectStart: String.Index?
    while let range = text.range(of: "= {", range: searchStart..<markerRange.lowerBound) {
        objectStart = range.lowerBound
        searchStart = range.upperBound
    }

    guard let assignmentStart = objectStart else { return nil }
    let start = text[..<assignmentStart].lastIndex(of: "\n")
        .map { text.index(after: $0) }
        ?? text.startIndex

    var index = assignmentStart
    var depth = 0
    while index < text.endIndex {
        let character = text[index]
        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                guard let semicolon = text[index...].firstIndex(of: ";") else { return nil }
                return start..<text.index(after: semicolon)
            }
        }
        index = text.index(after: index)
    }

    return nil
}
