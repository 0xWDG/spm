//
//  UninstallPackage.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Remote Swift package reference found in an Xcode project.
public struct XcodePackageReferenceInfo: Sendable {
    /// Xcode object identifier.
    public let id: String
    /// Repository URL stored by Xcode.
    public let url: String
    /// Package name derived from the URL.
    public let name: String
}

public extension SPM {
    /// Removes a Swift package and its linked products from the current Xcode project.
    static func uninstallSwiftPackageFromXcodeProject(packageInput: String, dryRun: Bool = false) throws {
        let projectURL = try findXcodeProject(in: SPMRuntime.current.workingDirectory)
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        let original = try String(contentsOf: pbxprojURL, encoding: .utf8)
        guard let reference = packageReference(in: original, matching: packageInput) else {
            throw SPMCommandError.failure("Package reference not found: \(packageInput)", exitCode: 2)
        }
        let updated = removePackageReference(reference, from: original)
        if dryRun {
            print(unifiedDiff(original: original, updated: updated, path: pbxprojURL.path))
            return
        }
        let backups = try applyFileTransaction(
            [FileChange(url: pbxprojURL, data: Data(updated.utf8))],
            createBackups: true
        )
        printC("Uninstalled \(reference.name) from \(projectURL.lastPathComponent)", color: CLIColors.green)
        printC("Backup: \(backups[0].path)", color: CLIColors.yellow)
    }

    /// Finds a package reference by URL, owner/repository shorthand, or package name.
    static func packageReference(in project: String, matching input: String) -> XcodePackageReferenceInfo? {
        let normalized = normalizedSwiftPackageURL(from: input)
        let requestedName = swiftPackageName(from: input)
        return xcodeObjectRanges(containing: "isa = XCRemoteSwiftPackageReference;", in: project)
            .compactMap { range -> XcodePackageReferenceInfo? in
                let object = String(project[range])
                guard let id = xcodeObjectID(from: object), let url = repositoryURL(from: object) else { return nil }
                let reference = XcodePackageReferenceInfo(id: id, url: url, name: swiftPackageName(from: url))
                return url == normalized || reference.name == requestedName ? reference : nil
            }
            .first
    }

    /// Extracts a repository URL from an Xcode package-reference object.
    static func repositoryURL(from object: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: #"repositoryURL = \"?([^\";]+)\"?;"#),
              let match = expression.firstMatch(
                in: object,
                range: NSRange(object.startIndex..<object.endIndex, in: object)
              ),
              let range = Range(match.range(at: 1), in: object)
        else { return nil }
        return String(object[range])
    }

    /// Removes package, product-dependency, build-file objects, and all list entries referencing them.
    static func removePackageReference(_ reference: XcodePackageReferenceInfo, from project: String) -> String {
        let productObjects = xcodeObjectRanges(containing: "isa = XCSwiftPackageProductDependency;", in: project)
            .filter { project[$0].contains("package = \(reference.id)") }
        let productIDs = productObjects.compactMap { xcodeObjectID(from: String(project[$0])) }
        let buildObjects = xcodeObjectRanges(containing: "isa = PBXBuildFile;", in: project).filter { range in
            productIDs.contains { project[range].contains("productRef = \($0)") }
        }
        let buildIDs = buildObjects.compactMap { xcodeObjectID(from: String(project[$0])) }
        let packageObjects = xcodeObjectRanges(containing: "isa = XCRemoteSwiftPackageReference;", in: project)
            .filter { xcodeObjectID(from: String(project[$0])) == reference.id }
        var updated = project
        for range in (productObjects + buildObjects + packageObjects).sorted(by: { $0.lowerBound > $1.lowerBound }) {
            updated.removeSubrange(range)
        }
        let identifiers = Set(productIDs + buildIDs + [reference.id])
        return updated.components(separatedBy: .newlines)
            .filter { line in !identifiers.contains { line.contains($0) } }
            .joined(separator: "\n")
    }
}
