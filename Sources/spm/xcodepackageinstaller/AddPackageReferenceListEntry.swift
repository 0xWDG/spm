//
//  AddPackageReferenceListEntry.swift
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
/// Adds a package reference entry to a PBXProject object.
static func addPackageReferenceListEntry(
    projectObject: String,
    packageID: String,
    packageName: String
) throws -> String {
    let entry = "\t\t\t\t\(packageID) /* XCRemoteSwiftPackageReference \"\(packageName)\" */,"

    if let referencesRange = projectObject.range(of: "packageReferences = (") {
        let searchRange = referencesRange.upperBound..<projectObject.endIndex
        guard let closeRange = projectObject.range(of: "\n\t\t\t);", range: searchRange) else {
            throw XcodePackageInstallerError.malformedProject("packageReferences list is missing its closing marker.")
        }

        var updated = projectObject
        updated.insert(contentsOf: "\n\(entry)", at: closeRange.lowerBound)
        return updated
    }

    let insertion: String
    if let productRefRange = projectObject.range(of: "\n\t\t\tproductRefGroup = ") {
        insertion = """

\t\t\tpackageReferences = (
\(entry)
\t\t\t);
"""
        var updated = projectObject
        updated.insert(contentsOf: insertion, at: productRefRange.lowerBound)
        return updated
    }

    guard let closingRange = projectObject.range(of: "\n\t\t};", options: .backwards) else {
        throw XcodePackageInstallerError.malformedProject("PBXProject object is missing its closing marker.")
    }

    insertion = """

\t\t\tpackageReferences = (
\(entry)
\t\t\t);
"""
    var updated = projectObject
    updated.insert(contentsOf: insertion, at: closingRange.lowerBound)
    return updated
}
}
