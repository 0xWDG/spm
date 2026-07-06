//
//  LibraryProducts.swift
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
/// Reads library product names from a remote package manifest, falling back to naming conventions.
static func libraryProducts(forPackageURL packageURL: String, fallbackPackageName: String) -> [String] {
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("swift-package-installer-\(UUID().uuidString)")

    defer {
        try? fileManager.removeItem(at: temporaryDirectory)
    }

    do {
        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let cloneURL = temporaryDirectory.appendingPathComponent("Package")
        _ = try runXcodePackageInstallerCommand("/usr/bin/git", [
            "clone",
            "--depth",
            "1",
            packageURL,
            cloneURL.path
        ])

        let manifestJSON = try runXcodePackageInstallerCommand("/usr/bin/swift", [
            "package",
            "--package-path",
            cloneURL.path,
            "dump-package"
        ])

        let manifest = try JSONDecoder().decode(
            XcodePackageManifest.self,
            from: Data(manifestJSON.utf8)
        )

        let libraries = manifest.products
            .filter { $0.type.library != nil }
            .map(\.name)

        if !libraries.isEmpty {
            return libraries
        }
    } catch {
        // Fall back to common package-to-product naming conventions when the
        // remote manifest cannot be inspected in this environment.
    }

    return possibleSwiftPackageProductNames(from: fallbackPackageName)
}
}
