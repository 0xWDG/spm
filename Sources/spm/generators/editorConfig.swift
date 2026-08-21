//
//  editorConfig.swift
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
/// Generates an .editorconfig file from configured or built-in settings.
static func generateEditorConfig(options: OverwriteOptions = OverwriteOptions()) throws {
    _ = try requiredProductName()
    let configuration = try activeConfiguration()
    let defaultEditorConfig = """
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
"""
    let editorConfig = renderTemplate(
        try configurationValueContent(
            configuration.editorconfig,
            fileNames: ["editorconfig", ".editorconfig"]
        ) ?? defaultEditorConfig,
        configuration: configuration
    )

    try writeGeneratedFile(editorConfig, to: projectURL(".editorconfig"), options: options)
    if !options.dryRun {
        printC("Generated .editorconfig", color: CLIColors.green)
    }
}
}
