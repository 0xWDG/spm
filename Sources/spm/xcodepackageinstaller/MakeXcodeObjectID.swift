//
//  MakeXcodeObjectID.swift
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
/// Creates a unique 24-character Xcode project object identifier.
static func makeXcodeObjectID(existingIn project: String) -> String {
    var id = ""
    repeat {
        id = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24).uppercased()
    } while project.contains(id)
    return id
}
}
