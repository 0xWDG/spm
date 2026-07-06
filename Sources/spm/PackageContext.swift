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

public nonisolated(unsafe) let fileManager = FileManager.default

public nonisolated(unsafe) var internalProductName: String?
public var productName: String {
    get {
        if let productName = internalProductName {
            return productName
        }

        if fileManager.fileExists(atPath: "Package.swift") {
            guard let package = try? String(contentsOf: URL(fileURLWithPath: "Package.swift"), encoding: .utf8),
                  let productName = packageName(from: package) else {
                printC("Could not find product name in Package.swift", color: CLIColors.red)
                exit(2)
            }

            return productName
        } else {
            printC("Package.swift not found, please provide package name", color: CLIColors.red)
            return ""
        }
    }
    set {
        internalProductName = newValue
    }
}

/// Extracts the package name from a Package.swift manifest.
public func packageName(from manifest: String) -> String? {
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
