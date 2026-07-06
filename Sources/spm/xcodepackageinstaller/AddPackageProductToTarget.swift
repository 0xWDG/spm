//
//  AddPackageProductToTarget.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Links a Swift package product dependency into a native target.
public func addPackageProductToTarget(
    project: String,
    target: XcodeNativeTarget,
    packageID: String,
    packageName: String,
    productName: String
) throws -> String {
    var updated = project
    let productDependencyID = existingProductDependencyID(
        inXcodeProject: updated,
        packageID: packageID,
        productName: productName
    ) ?? makeXcodeObjectID(existingIn: updated)
    let buildFileID = existingBuildFileID(
        inXcodeProject: updated,
        productDependencyID: productDependencyID
    ) ?? makeXcodeObjectID(existingIn: updated + productDependencyID)

    guard let currentTargetRange = xcodeObjectRange(withID: target.id, in: updated) else {
        throw XcodePackageInstallerError.malformedProject("could not find native target \(target.name).")
    }

    let targetObject = String(updated[currentTargetRange])
    let dependencyEntry = "\t\t\t\t\(productDependencyID) /* \(productName) */,"
    let updatedTarget = try addXcodeListEntry(
        object: targetObject,
        listName: "packageProductDependencies",
        entry: dependencyEntry
    )
    updated.replaceSubrange(currentTargetRange, with: updatedTarget)

    guard let phaseRange = xcodeObjectRange(withID: target.frameworksBuildPhaseID, in: updated) else {
        throw XcodePackageInstallerError.malformedProject("could not find Frameworks build phase for target \(target.name).")
    }

    let phaseObject = String(updated[phaseRange])
    let buildFileEntry = "\t\t\t\t\(buildFileID) /* \(productName) in Frameworks */,"
    let updatedPhase = try addXcodeListEntry(
        object: phaseObject,
        listName: "files",
        entry: buildFileEntry
    )
    updated.replaceSubrange(phaseRange, with: updatedPhase)

    if existingBuildFileID(inXcodeProject: updated, productDependencyID: productDependencyID) == nil {
        updated = try insertXcodeObject(
            buildFileObject(
                buildFileID: buildFileID,
                productDependencyID: productDependencyID,
                productName: productName
            ),
            intoSectionNamed: "PBXBuildFile",
            in: updated,
            before: "PBXFileReference"
        )
    }

    if existingProductDependencyID(inXcodeProject: updated, packageID: packageID, productName: productName) == nil {
        updated = try insertXcodeObject(
            swiftPackageProductDependencyObject(
                productDependencyID: productDependencyID,
                packageID: packageID,
                packageName: packageName,
                productName: productName
            ),
            intoSectionNamed: "XCSwiftPackageProductDependency",
            in: updated,
            before: "XCBuildConfiguration"
        )
    }

    return updated
}
