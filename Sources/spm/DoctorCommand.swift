//
//  DoctorCommand.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// One environment diagnostic reported by `spm doctor`.
public struct DoctorCheck: Codable, Sendable {
    /// Diagnostic name.
    public let name: String
    /// Whether the check passed.
    public let passed: Bool
    /// Whether failure prevents core functionality.
    public let required: Bool
    /// Human-readable diagnostic detail.
    public let detail: String
}

public extension SPM {
    /// Checks the local development environment and project configuration.
    static func doctor() throws {
        let checks = doctorChecks()
        if outputOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(checks)
            print(String(data: data, encoding: .utf8) ?? "[]")
        } else if !outputOptions.quiet {
            for check in checks {
                let marker = check.passed ? "PASS" : (check.required ? "FAIL" : "WARN")
                let color = check.passed ? CLIColors.green : (check.required ? CLIColors.red : CLIColors.yellow)
                emit("[\(marker)] \(check.name): \(check.detail)", color: color)
            }
        }

        let failed = checks.filter { $0.required && !$0.passed }
        guard failed.isEmpty else {
            throw SPMCommandError.failure(
                "Doctor found \(failed.count) required check(s) that need attention.",
                exitCode: 1
            )
        }
    }

    /// Returns environment diagnostics without terminating the process.
    static func doctorChecks() -> [DoctorCheck] {
        var checks = [
            commandCheck(name: "Swift", executable: "/usr/bin/env", arguments: ["swift", "--version"], required: true),
            commandCheck(name: "Git", executable: "/usr/bin/git", arguments: ["--version"], required: true),
            commandCheck(name: "DocC", executable: "/usr/bin/xcrun", arguments: ["--find", "docc"], required: true),
            commandCheck(
                name: "SwiftLint",
                executable: "/usr/bin/env",
                arguments: ["swiftlint", "version"],
                required: false
            )
        ]

        let manifest = projectURL("Package.swift")
        checks.append(DoctorCheck(
            name: "Package manifest",
            passed: fileManager.fileExists(atPath: manifest.path),
            required: true,
            detail: fileManager.fileExists(atPath: manifest.path) ? manifest.path : "Package.swift not found"
        ))

        do {
            _ = try activeConfiguration()
            checks.append(DoctorCheck(name: "Configuration", passed: true, required: true, detail: "valid"))
        } catch {
            checks.append(DoctorCheck(name: "Configuration", passed: false, required: true, detail: "\(error)"))
        }
        return checks
    }

    /// Runs one executable availability check.
    private static func commandCheck(
        name: String,
        executable: String,
        arguments: [String],
        required: Bool
    ) -> DoctorCheck {
        do {
            let result = try ProcessRunner().run(executable: executable, arguments: arguments, timeout: 15)
            let output = (result.standardOutput.isEmpty ? result.standardError : result.standardOutput)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .first ?? "available"
            return DoctorCheck(name: name, passed: result.status == 0, required: required, detail: output)
        } catch {
            return DoctorCheck(name: name, passed: false, required: required, detail: "\(error)")
        }
    }
}
