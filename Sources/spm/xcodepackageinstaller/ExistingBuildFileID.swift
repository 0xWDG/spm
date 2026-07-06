//
//  ExistingBuildFileID.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Finds an existing build file identifier for a product dependency.
public func existingBuildFileID(inXcodeProject project: String, productDependencyID: String) -> String? {
    xcodeObjectRanges(containing: "isa = PBXBuildFile;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("productRef = \(productDependencyID)") else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}
