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
nonisolated(unsafe) public let fileManager = FileManager.default

/// Cached package product name set by command-line operations.
nonisolated(unsafe) public var internalProductName: String?

/// Current package product name, inferred from Package.swift when not explicitly set.
public var productName: String {
    get {
        if let productName = internalProductName {
            return productName
        }

        if fileManager.fileExists(atPath: "Package.swift") {
            guard let package = try? String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8),
                  let productName = spm.packageName(from: package) else {
                spm.printC("Could not find product name in Package.swift", color: CLIColors.red)
                exit(2)
            }

            return productName
        } else {
            spm.printC("Package.swift not found, please provide package name", color: CLIColors.red)
            return ""
        }
    }
    set {
        internalProductName = newValue
    }
}

public extension spm {
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
