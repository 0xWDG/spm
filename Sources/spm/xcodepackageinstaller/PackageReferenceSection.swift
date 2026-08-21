//
//  PackageReferenceSection.swift
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
/// Generates an `XCRemoteSwiftPackageReference` section for inclusion in an Xcode project file.
/// - Parameters:
///   - packageID: The unique identifier for the package reference.
///   - packageName: The name of the package.
///   - packageURL: The URL of the package repository.
///   - requirement: The version requirement for the package.
/// - Returns: A string representing the `XCRemoteSwiftPackageReference` section.
static func packageReferenceSection(
    packageID: String,
    packageName: String,
    packageURL: String,
    requirement: XcodePackageRequirement
) -> String {
    let requirementBody = requirement.lines.map { "\t\t\t\t\($0)" }.joined(separator: "\n")
    return """

/* Begin XCRemoteSwiftPackageReference section */
\t\t\(packageID) /* XCRemoteSwiftPackageReference "\(packageName)" */ = {
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = \(packageURL);
\t\t\trequirement = {
\(requirementBody)
\t\t\t};
\t\t};
/* End XCRemoteSwiftPackageReference section */

"""
}
}
