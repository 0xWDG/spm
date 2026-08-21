//
//  ConfigurationValidation.swift
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
    /// Validates configuration syntax, identity values, URLs, and referenced templates.
    static func validateConfiguration() throws {
        let configuration = try activeConfiguration()
        var problems: [String] = []
        if let email = configuration.email, !email.contains("@") {
            problems.append("email is not valid")
        }
        if let website = configuration.website, URL(string: website)?.scheme == nil {
            problems.append("website must be an absolute URL")
        }
        if let github = configuration.github, github.trimmingCharacters(in: .whitespaces).isEmpty {
            problems.append("github cannot be empty")
        }

        _ = try configurationValueContent(configuration.readme, fileNames: ["README.md"])
        _ = try configurationValueContent(configuration.licence, fileNames: ["LICENCE.md", "LICENSE.md"])
        _ = try configurationValueContent(configuration.swiftFileHeader, fileNames: ["HEADER.swift", ".swiftfile"])
        _ = try configurationValueContent(configuration.editorconfig, fileNames: [".editorconfig"])
        _ = try configurationValueContent(configuration.gitignore, fileNames: [".gitignore"])
        _ = try configurationValueContent(configuration.swiftLintRules, fileNames: [".swiftlint.yml"])

        guard problems.isEmpty else {
            throw SPMCommandError.failure(
                "Invalid configuration:\n- \(problems.joined(separator: "\n- "))",
                exitCode: 1
            )
        }
        printC("Configuration is valid", color: CLIColors.green)
    }
}
