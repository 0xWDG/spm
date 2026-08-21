//
//  PackageContext.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Shared file manager used by command helpers.
public var fileManager: FileManager { SPMRuntime.current.fileManager }

/// Cached package product name set by command-line operations.
nonisolated(unsafe) public var internalProductName: String?

/// Current package product name, inferred from Package.swift when not explicitly set.
public var productName: String {
    get {
        if let productName = internalProductName {
            return productName
        }

        let manifestURL = SPM.projectURL("Package.swift")
        if fileManager.fileExists(atPath: manifestURL.path) {
            let package = try? String(contentsOf: manifestURL, encoding: .utf8)
            return package.flatMap(SPM.packageName(from:)) ?? ""
        }

        return ""
    }
    set {
        internalProductName = newValue
    }
}

public extension SPM {
/// Returns the current package name or throws when it cannot be determined.
static func requiredProductName() throws -> String {
    guard !productName.isEmpty else {
        if fileManager.fileExists(atPath: projectURL("Package.swift").path) {
            throw SPMCommandError.failure("Could not find the package name in Package.swift.", exitCode: 2)
        }

        throw SPMCommandError.failure("Package.swift not found.", exitCode: 2)
    }

    return productName
}

/// Extracts the package name from a Package.swift manifest.
static func packageName(from manifest: String) -> String? {
    guard let regularExpression = try? NSRegularExpression(pattern: #"name\s*:\s*"([^"]+)""#) else {
        return nil
    }

    let range = NSRange(manifest.startIndex..<manifest.endIndex, in: manifest)
    guard let match = regularExpression.firstMatch(in: manifest, range: range),
          let nameRange = Range(match.range(at: 1), in: manifest) else {
        return nil
    }

    return String(manifest[nameRange])
}
}
