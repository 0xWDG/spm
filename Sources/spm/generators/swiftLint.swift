//
//  swiftLint.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Generates a .swiftlint.yml file from configured or built-in SwiftLint rules.
public func generateSwiftLint() {
    let configuration = activeConfiguration()
    let defaultSwiftLint = """
excluded:
  - "*resource_bundle_accessor*" # SwiftPM Generated
  - ".build/*"

opt_in_rules:
   - missing_docs
   - empty_count
   - empty_string
   - toggle_bool
   - unused_optional_binding
   - valid_ibinspectable
   - modifier_order
   - first_where
   - fatal_error_message
   - force_unwrapping
"""
    let swiftLint = renderTemplate(
        configurationValueContent(
            configuration.swiftLintRules,
            fileNames: ["swiftlint.yml", ".swiftlint.yml"]
        ) ?? defaultSwiftLint,
        configuration: configuration
    )

    do {
        try swiftLint.write(to: URL(fileURLWithPath: ".swiftlint.yml"), atomically: true, encoding: .utf8)
        printC("Generated .swiftlint.yml", color: CLIColors.green)
    } catch {
        printC("Failed to generate .swiftlint.yml", color: CLIColors.red)
    }
}
