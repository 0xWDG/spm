//
//  CompileExecutable.swift
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
    /// Compiles all source files into a local executable named `spm`.
    static func compileExecutable(options: OverwriteOptions = OverwriteOptions()) throws {
        let destination = projectURL("spm")
        if fileManager.fileExists(atPath: destination.path) && !options.force && !options.dryRun {
            throw SPMCommandError.fileExists(destination.path)
        }

        if options.dryRun {
            print("Would build the release product and write \(destination.path)")
            return
        }

        let result = try ProcessRunner().run(
            executable: "/usr/bin/env",
            arguments: ["swift", "build", "-c", "release", "--product", "spm"],
            workingDirectory: projectURL(),
            timeout: 600
        )
        guard result.status == 0 else {
            throw SPMCommandError.failure(
                "Failed to compile executable: \(result.standardError)",
                exitCode: result.status
            )
        }

        let builtExecutable = projectURL(".build/release/spm")
        guard fileManager.fileExists(atPath: builtExecutable.path) else {
            throw SPMCommandError.failure("Release executable not found at \(builtExecutable.path).", exitCode: 4)
        }

        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: builtExecutable, to: destination)
        } catch {
            throw SPMCommandError.failure("Failed to write \(destination.path): \(error)", exitCode: 4)
        }

        printC("Executable compiled successfully", color: CLIColors.green)
    }
}
