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

/// Installs and links a Swift package in the Xcode project in the current directory.
public func installSwiftPackageInXcodeProject(packageURL packageInput: String) throws {
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
        guard let pbxProjectRange = xcodeObjectRange(containing: "isa = PBXProject;", in: project) else {
            throw XcodePackageInstallerError.missingPBXProject
        }

        let projectObject = String(project[pbxProjectRange])
        let updatedProjectObject = try addPackageReferenceListEntry(
            projectObject: projectObject,
            packageID: id,
            packageName: name
        )
        project.replaceSubrange(pbxProjectRange, with: updatedProjectObject)
        project = try insertPackageReferenceObject(
            into: project,
            packageID: id,
            packageName: name,
            packageURL: packageURL,
            requirement: resolvedRequirement
        )
    }

    for target in targets {
        for productName in productNames {
            project = try addPackageProductToTarget(
                project: project,
                target: target,
                packageID: id,
                packageName: name,
                productName: productName
            )
        }
    }

    let backupURL = pbxprojURL.deletingLastPathComponent()
        .appendingPathComponent("project.pbxproj.backup-\(Int(Date().timeIntervalSince1970))")
    try fileManager.copyItem(at: pbxprojURL, to: backupURL)
    try project.write(to: pbxprojURL, atomically: true, encoding: .utf8)

    printC("Installed \(name) in \(projectURL.lastPathComponent)", color: CLIColors.green)
    printC("Linked products: \(productNames.joined(separator: ", "))", color: CLIColors.green)
    printC("Targets: \(targets.map(\.name).joined(separator: ", "))", color: CLIColors.green)
    printC("Backup: \(backupURL.path)", color: CLIColors.yellow)
}
