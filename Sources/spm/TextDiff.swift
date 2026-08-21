//
//  TextDiff.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public extension SPM {
    /// Produces a readable line-oriented diff for previews.
    static func unifiedDiff(original: String, updated: String, path: String) -> String {
        guard original != updated else { return "No changes for \(path)" }
        let oldLines = original.components(separatedBy: .newlines)
        let newLines = updated.components(separatedBy: .newlines)
        var output = ["--- a/\(path)", "+++ b/\(path)"]
        let count = max(oldLines.count, newLines.count)
        for index in 0..<count {
            let old = index < oldLines.count ? oldLines[index] : nil
            let new = index < newLines.count ? newLines[index] : nil
            if old == new { continue }
            if let old { output.append("-\(old)") }
            if let new { output.append("+\(new)") }
        }
        return output.joined(separator: "\n")
    }
}
