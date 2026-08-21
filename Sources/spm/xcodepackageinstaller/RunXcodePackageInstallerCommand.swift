//
//  RunXcodePackageInstallerCommand.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public extension SPM {
/// Runs a process and returns standard output when the command succeeds.
static func runXcodePackageInstallerCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
    let result = try ProcessRunner().run(
        executable: launchPath,
        arguments: arguments,
        workingDirectory: SPMRuntime.current.workingDirectory
    )
    guard result.status == 0 else {
        let command = ([launchPath] + arguments).joined(separator: " ")
        let details = result.standardError.isEmpty ? result.standardOutput : result.standardError
        let message = "Command failed: \(command)\n\(details)"
        throw XcodePackageInstallerError.commandFailed(message)
    }

    return result.standardOutput
}
}
