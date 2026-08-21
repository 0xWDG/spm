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

public extension SPM {
/// Links a Swift package product dependency into a native target.
static func addPackageProductToTarget(
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

    updated = try addPackageProductDependency(
        to: updated,
        target: target,
        productDependencyID: productDependencyID,
        productName: productName
    )
    updated = try addFrameworksBuildFile(
        to: updated,
        target: target,
        buildFileID: buildFileID,
        productName: productName
    )
    updated = try insertMissingBuildFileObject(
        into: updated,
        productDependencyID: productDependencyID,
        buildFileID: buildFileID,
        productName: productName
    )
    updated = try insertMissingProductDependencyObject(
        into: updated,
        packageID: packageID,
        packageName: packageName,
        productName: productName,
        productDependencyID: productDependencyID
    )
    return updated
}

/// Adds a package product dependency to a native target object.
static func addPackageProductDependency(
    to project: String,
    target: XcodeNativeTarget,
    productDependencyID: String,
    productName: String
) throws -> String {
    guard let currentTargetRange = xcodeObjectRange(withID: target.id, in: project) else {
        throw XcodePackageInstallerError.malformedProject("could not find native target \(target.name).")
    }

    var updated = project
    let targetObject = String(updated[currentTargetRange])
    let dependencyEntry = "\t\t\t\t\(productDependencyID) /* \(productName) */,"
    let updatedTarget = try addXcodeListEntry(
        object: targetObject,
        listName: "packageProductDependencies",
        entry: dependencyEntry
    )
    updated.replaceSubrange(currentTargetRange, with: updatedTarget)
    return updated
}

/// Adds the package product build file to the target Frameworks phase.
static func addFrameworksBuildFile(
    to project: String,
    target: XcodeNativeTarget,
    buildFileID: String,
    productName: String
) throws -> String {
    guard let phaseRange = xcodeObjectRange(withID: target.frameworksBuildPhaseID, in: project) else {
        throw XcodePackageInstallerError.malformedProject(
            "could not find Frameworks build phase for target \(target.name)."
        )
    }

    var updated = project
    let phaseObject = String(updated[phaseRange])
    let buildFileEntry = "\t\t\t\t\(buildFileID) /* \(productName) in Frameworks */,"
    let updatedPhase = try addXcodeListEntry(
        object: phaseObject,
        listName: "files",
        entry: buildFileEntry
    )
    updated.replaceSubrange(phaseRange, with: updatedPhase)
    return updated
}

/// Inserts a missing PBXBuildFile object.
static func insertMissingBuildFileObject(
    into project: String,
    productDependencyID: String,
    buildFileID: String,
    productName: String
) throws -> String {
    guard existingBuildFileID(inXcodeProject: project, productDependencyID: productDependencyID) == nil else {
        return project
    }

    return try insertXcodeObject(
        buildFileObject(
            buildFileID: buildFileID,
            productDependencyID: productDependencyID,
            productName: productName
        ),
        intoSectionNamed: "PBXBuildFile",
        in: project,
        before: "PBXFileReference"
    )
}

/// Inserts a missing XCSwiftPackageProductDependency object.
static func insertMissingProductDependencyObject(
    into project: String,
    packageID: String,
    packageName: String,
    productName: String,
    productDependencyID: String
) throws -> String {
    let existingID = existingProductDependencyID(
        inXcodeProject: project,
        packageID: packageID,
        productName: productName
    )
    guard existingID == nil else {
        return project
    }

    return try insertXcodeObject(
        swiftPackageProductDependencyObject(
            productDependencyID: productDependencyID,
            packageID: packageID,
            packageName: packageName,
            productName: productName
        ),
        intoSectionNamed: "XCSwiftPackageProductDependency",
        in: project,
        before: "XCBuildConfiguration"
    )
}
}
