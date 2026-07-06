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

/// Generates an .editorconfig file from configured or built-in settings.
public func generateEditorConfig() {
    let configuration = activeConfiguration()
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
        configurationValueContent(
            configuration.editorconfig,
            fileNames: ["editorconfig", ".editorconfig"]
        ) ?? defaultEditorConfig,
        configuration: configuration
    )

    do {
        try editorConfig.write(to: URL(fileURLWithPath: ".editorconfig"), atomically: true, encoding: .utf8)
        printC("Generated .editorconfig", color: CLIColors.green)
    } catch {
        printC("Failed to generate .editorconfig", color: CLIColors.red)
    }
}
