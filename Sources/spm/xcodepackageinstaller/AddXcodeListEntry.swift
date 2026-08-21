//
//  AddXcodeListEntry.swift
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
/// Adds an entry to a named Xcode object list, creating the list when needed.
static func addXcodeListEntry(object: String, listName: String, entry: String) throws -> String {
    if let blockRange = xcodeListBlockRange(named: listName, in: object) {
        if object[blockRange].contains(entry) {
            return object
        }

        let searchRange = blockRange.lowerBound..<blockRange.upperBound
        guard let closeRange = object.range(of: "\n\t\t\t);", range: searchRange) else {
            throw XcodePackageInstallerError.malformedProject("\(listName) list is missing its closing marker.")
        }

        var updated = object
        updated.insert(contentsOf: "\n\(entry)", at: closeRange.lowerBound)
        return updated
    }

    guard let closingRange = object.range(of: "\n\t\t};", options: .backwards) else {
        throw XcodePackageInstallerError.malformedProject("object is missing its closing marker.")
    }

    let insertion = """

\t\t\t\(listName) = (
\(entry)
\t\t\t);
"""
    var updated = object
    updated.insert(contentsOf: insertion, at: closingRange.lowerBound)
    return updated
}
}
