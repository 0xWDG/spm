//
//  SwiftPackageProductDependencyObject.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Builds an XCSwiftPackageProductDependency object.
public func swiftPackageProductDependencyObject(productDependencyID: String, packageID: String, packageName: String, productName: String) -> String {
    """
\t\t\(productDependencyID) /* \(productName) */ = {
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = \(packageID) /* XCRemoteSwiftPackageReference "\(packageName)" */;
\t\t\tproductName = \(productName);
\t\t};

"""
}
