//
//  StringHelpers.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public extension String {
    /// Returns nil when the string is empty.
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    /// Expands a leading tilde in a filesystem path.
    var expandingTildeInPath: String {
        NSString(string: self).expandingTildeInPath
    }
}
