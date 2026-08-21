//
//  InsertPackageReferenceObject.swift
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
/// Inserts a Swift package reference object into an Xcode project file.
static func insertPackageReferenceObject(
    into project: String,
    packageID: String,
    packageName: String,
    packageURL: String,
    requirement: XcodePackageRequirement
) throws -> String {
    if let endSection = project.range(of: "/* End XCRemoteSwiftPackageReference section */") {
        var updated = project
        updated.insert(
            contentsOf: packageReferenceObject(
                packageID: packageID,
                packageName: packageName,
                packageURL: packageURL,
                requirement: requirement
            ),
            at: endSection.lowerBound
        )
        return updated
    }

    guard let insertionPoint = project.range(of: "/* Begin XCBuildConfiguration section */")?.lowerBound
        ?? project.range(of: "/* End PBXProject section */")?.upperBound
    else {
        throw XcodePackageInstallerError.malformedProject(
            "could not find a safe place to insert the package reference section."
        )
    }

    var updated = project
    updated.insert(
        contentsOf: packageReferenceSection(
            packageID: packageID,
            packageName: packageName,
            packageURL: packageURL,
            requirement: requirement
        ),
        at: insertionPoint
    )
    return updated
}
}
