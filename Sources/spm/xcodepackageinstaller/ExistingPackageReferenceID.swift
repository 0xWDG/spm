//
//  ExistingPackageReferenceID.swift
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
/// Finds an existing package reference identifier for a package URL.
static func existingPackageReferenceID(inXcodeProject project: String, packageURL: String) -> String? {
    xcodeObjectRanges(containing: "isa = XCRemoteSwiftPackageReference;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("repositoryURL = \(packageURL);")
                || object.contains("repositoryURL = \"\(packageURL)\";")
            else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}
}
