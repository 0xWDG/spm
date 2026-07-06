//
//  XcodePackageInstaller.swift
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
/// Installs and links a Swift package in the Xcode project in the current directory.
static func installSwiftPackageInXcodeProject(packageURL packageInput: String) throws {
    let packageURL = normalizedSwiftPackageURL(from: packageInput)
    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let projectURL = try findXcodeProject(in: currentDirectory)
    let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
    var project = try String(contentsOf: pbxprojURL, encoding: .utf8)

    let name = swiftPackageName(from: packageURL)
    let existingID = existingPackageReferenceID(inXcodeProject: project, packageURL: packageURL)
    let id = existingID ?? makeXcodeObjectID(existingIn: project)
    let resolvedRequirement = packageRequirement(forPackageURL: packageURL)
    let targets = nativeTargets(inXcodeProject: project)
    guard !targets.isEmpty else {
        throw XcodePackageInstallerError.noLinkableTarget
    }

    let productNames = libraryProducts(forPackageURL: packageURL, fallbackPackageName: name)

    if existingID == nil {
        project = try addPackageReference(
            to: project,
            packageID: id,
            packageName: name,
            packageURL: packageURL,
            requirement: resolvedRequirement
        )
    }
    project = try linkPackageProducts(
        in: project,
        targets: targets,
        packageID: id,
        packageName: name,
        productNames: productNames
    )

    let backupURL = pbxprojURL.deletingLastPathComponent()
        .appendingPathComponent("project.pbxproj.backup-\(Int(Date().timeIntervalSince1970))")
    try fileManager.copyItem(at: pbxprojURL, to: backupURL)
    try project.write(to: pbxprojURL, atomically: true, encoding: .utf8)

    printPackageInstallSuccess(
        name: name,
        projectURL: projectURL,
        productNames: productNames,
        targets: targets,
        backupURL: backupURL
    )
}

/// Adds a package reference to the PBXProject object and package reference section.
static func addPackageReference(
    to project: String,
    packageID: String,
    packageName: String,
    packageURL: String,
    requirement: XcodePackageRequirement
) throws -> String {
    guard let pbxProjectRange = xcodeObjectRange(containing: "isa = PBXProject;", in: project) else {
        throw XcodePackageInstallerError.missingPBXProject
    }

    var updated = project
    let projectObject = String(updated[pbxProjectRange])
    let updatedProjectObject = try addPackageReferenceListEntry(
        projectObject: projectObject,
        packageID: packageID,
        packageName: packageName
    )
    updated.replaceSubrange(pbxProjectRange, with: updatedProjectObject)
    return try insertPackageReferenceObject(
        into: updated,
        packageID: packageID,
        packageName: packageName,
        packageURL: packageURL,
        requirement: requirement
    )
}

/// Links package products into all target Frameworks build phases.
static func linkPackageProducts(
    in project: String,
    targets: [XcodeNativeTarget],
    packageID: String,
    packageName: String,
    productNames: [String]
) throws -> String {
    var updated = project
    for target in targets {
        for productName in productNames {
            updated = try addPackageProductToTarget(
                project: updated,
                target: target,
                packageID: packageID,
                packageName: packageName,
                productName: productName
            )
        }
    }
    return updated
}

/// Prints the package installation summary.
static func printPackageInstallSuccess(
    name: String,
    projectURL: URL,
    productNames: [String],
    targets: [XcodeNativeTarget],
    backupURL: URL
) {
    printC("Installed \(name) in \(projectURL.lastPathComponent)", color: CLIColors.green)
    printC("Linked products: \(productNames.joined(separator: ", "))", color: CLIColors.green)
    printC("Targets: \(targets.map(\.name).joined(separator: ", "))", color: CLIColors.green)
    printC("Backup: \(backupURL.path)", color: CLIColors.yellow)
}
}
