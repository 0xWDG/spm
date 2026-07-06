//
//  ExistingProductDependencyID.swift
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
/// Finds an existing Swift package product dependency identifier.
static func existingProductDependencyID(
    inXcodeProject project: String,
    packageID: String,
    productName: String
) -> String? {
    xcodeObjectRanges(containing: "isa = XCSwiftPackageProductDependency;", in: project)
        .compactMap { range -> String? in
            let object = String(project[range])
            guard object.contains("package = \(packageID)")
                && object.contains("productName = \(productName);")
            else {
                return nil
            }

            return xcodeObjectID(from: object)
        }
        .first
}
}
