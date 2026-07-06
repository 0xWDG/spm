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

/// Runs a process and returns standard output when the command succeeds.
public func runXcodePackageInstallerCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
    let process = Process()
    let output = Pipe()
    let error = Pipe()

    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = error

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    guard process.terminationStatus == 0 else {
        let command = ([launchPath] + arguments).joined(separator: " ")
        throw XcodePackageInstallerError.commandFailed("Command failed: \(command)\n\(stderr.isEmpty ? stdout : stderr)")
    }

    return stdout
}
