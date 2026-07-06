//
//  BuildFileObject.swift
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
/// Builds a PBXBuildFile object for a Swift package product dependency.
static func buildFileObject(buildFileID: String, productDependencyID: String, productName: String) -> String {
    """
\t\t\(buildFileID) /* \(productName) in Frameworks */ = {
\t\t\tisa = PBXBuildFile;
\t\t\tproductRef = \(productDependencyID) /* \(productName) */;
\t\t};

"""
}
}
