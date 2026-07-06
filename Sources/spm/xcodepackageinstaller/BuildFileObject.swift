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

/// Builds a PBXBuildFile object for a Swift package product dependency.
public func buildFileObject(buildFileID: String, productDependencyID: String, productName: String) -> String {
    """
\t\t\(buildFileID) /* \(productName) in Frameworks */ = {isa = PBXBuildFile; productRef = \(productDependencyID) /* \(productName) */; };

"""
}
