//
//  InsertXcodeObject.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Inserts an Xcode object into an existing or newly created project section.
public func insertXcodeObject(_ object: String, intoSectionNamed section: String, in project: String, before fallbackSection: String) throws -> String {
    let endMarker = "/* End \(section) section */"
    if let endSection = project.range(of: endMarker) {
        var updated = project
        updated.insert(contentsOf: object, at: endSection.lowerBound)
        return updated
    }

    let fullSection = """

/* Begin \(section) section */
\(object)/* End \(section) section */

"""

    guard let insertionPoint = project.range(of: "/* Begin \(fallbackSection) section */")?.lowerBound
        ?? project.range(of: "/* End PBXProject section */")?.upperBound
    else {
        throw XcodePackageInstallerError.malformedProject("could not find a safe place to insert the \(section) section.")
    }

    var updated = project
    updated.insert(contentsOf: fullSection, at: insertionPoint)
    return updated
}
