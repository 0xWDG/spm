//
//  XcodeObjectRangesContaining.swift
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
/// Finds all Xcode object ranges containing a marker.
static func xcodeObjectRanges(containing marker: String, in text: String) -> [Range<String.Index>] {
    var ranges: [Range<String.Index>] = []
    var searchStart = text.startIndex

    while let markerRange = text.range(of: marker, range: searchStart..<text.endIndex) {
        var assignmentSearchStart = text.startIndex
        var assignmentStart: String.Index?

        while let assignmentRange = text.range(of: "= {", range: assignmentSearchStart..<markerRange.lowerBound) {
            assignmentStart = assignmentRange.lowerBound
            assignmentSearchStart = assignmentRange.upperBound
        }

        if let assignmentStart {
            let objectStart = text[..<assignmentStart].lastIndex(of: "\n")
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
                        if let semicolon = text[index...].firstIndex(of: ";") {
                            ranges.append(objectStart..<text.index(after: semicolon))
                            searchStart = text.index(after: semicolon)
                        } else {
                            searchStart = markerRange.upperBound
                        }
                        break
                    }
                }
                index = text.index(after: index)
            }
        } else {
            searchStart = markerRange.upperBound
        }

        if searchStart <= markerRange.lowerBound {
            searchStart = markerRange.upperBound
        }
    }

    return ranges
}
}
