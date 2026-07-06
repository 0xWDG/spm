//
//  FindXcodeProject.swift
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
/// Finds the single Xcode project in a directory.
static func findXcodeProject(in directory: URL) throws -> URL {
    let contents = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    let projects = contents
        .filter { $0.pathExtension == "xcodeproj" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    if projects.isEmpty {
        throw XcodePackageInstallerError.noProjectFound
    }

    if projects.count > 1 {
        throw XcodePackageInstallerError.multipleProjectsFound(projects.map(\.lastPathComponent))
    }

    return projects[0]
}
}
