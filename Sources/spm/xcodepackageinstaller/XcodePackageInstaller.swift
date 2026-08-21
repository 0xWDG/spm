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

/// Options for linking a package into an Xcode project.
public struct PackageInstallOptions: Equatable {
    /// Requested native target names; empty selects all compatible targets.
    public let targets: [String]
    /// Requested library product names; empty selects all discovered products.
    public let products: [String]
    /// Previews the project diff without writing.
    public let dryRun: Bool

    /// Creates package installation options.
    public init(targets: [String] = [], products: [String] = [], dryRun: Bool = false) {
        self.targets = targets
        self.products = products
        self.dryRun = dryRun
    }
}

public extension SPM {
/// Installs and links a Swift package in the Xcode project in the current directory.
static func installSwiftPackageInXcodeProject(
    packageURL packageInput: String,
    options: PackageInstallOptions = PackageInstallOptions()
) throws {
    let packageURL = normalizedSwiftPackageURL(from: packageInput)
    let currentDirectory = SPMRuntime.current.workingDirectory
    let projectURL = try findXcodeProject(in: currentDirectory)
    let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
    var project = try String(contentsOf: pbxprojURL, encoding: .utf8)

    let name = swiftPackageName(from: packageURL)
    let existingID = existingPackageReferenceID(inXcodeProject: project, packageURL: packageURL)
    let id = existingID ?? makeXcodeObjectID(existingIn: project)
    let resolvedRequirement = packageRequirement(forPackageURL: packageURL)
    let targets = try selectedTargets(in: project, requested: options.targets)
    let productNames = try selectedProducts(
        packageURL: packageURL,
        packageName: name,
        requested: options.products
    )

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

    if options.dryRun {
        let original = try String(contentsOf: pbxprojURL, encoding: .utf8)
        print(unifiedDiff(original: original, updated: project, path: pbxprojURL.path))
        return
    }

    let backups = try applyFileTransaction(
        [FileChange(url: pbxprojURL, data: Data(project.utf8))],
        createBackups: true
    )
    let backupURL = backups[0]

    printPackageInstallSuccess(
        name: name,
        projectURL: projectURL,
        productNames: productNames,
        targets: targets,
        backupURL: backupURL
    )
}

/// Resolves requested target names against native targets in an Xcode project.
private static func selectedTargets(in project: String, requested: [String]) throws -> [XcodeNativeTarget] {
    let available = nativeTargets(inXcodeProject: project)
    let missing = requested.filter { name in !available.contains { $0.name == name } }
    guard missing.isEmpty else {
        throw SPMCommandError.failure("Unknown Xcode target(s): \(missing.joined(separator: ", "))", exitCode: 2)
    }
    let selected = requested.isEmpty ? available : available.filter { requested.contains($0.name) }
    guard !selected.isEmpty else { throw XcodePackageInstallerError.noLinkableTarget }
    return selected
}

/// Resolves requested products against products published by a remote package.
private static func selectedProducts(
    packageURL: String,
    packageName: String,
    requested: [String]
) throws -> [String] {
    let available = libraryProducts(forPackageURL: packageURL, fallbackPackageName: packageName)
    let missing = requested.filter { !available.contains($0) }
    guard missing.isEmpty else {
        throw SPMCommandError.failure(
            "Unknown package product(s): \(missing.joined(separator: ", "))",
            exitCode: 2
        )
    }
    return requested.isEmpty ? available : available.filter { requested.contains($0) }
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
