//
//  CompletionCommand.swift
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
    /// Prints a completion script for a supported shell.
    static func generateCompletion(for shell: String) throws {
        print(try completionScript(for: shell))
    }

    /// Returns a completion script for a supported shell.
    static func completionScript(for shell: String) throws -> String {
        let commands = [
            "build", "completion", "config", "create", "diff", "doctor", "documentation",
            "editorconfig", "executable", "gitignore", "header", "install", "licence", "readme",
            "swiftlint", "test", "uninstall", "version"
        ].joined(separator: " ")

        switch shell.lowercased() {
        case "zsh":
            return "#compdef spm\n_arguments '1:command:(\(commands))' '*::argument:->args'"
        case "bash":
            return """
            _spm_completion() {
                if [[ ${COMP_CWORD} -eq 1 ]]; then
                    COMPREPLY=( $(compgen -W "\(commands)" -- "${COMP_WORDS[COMP_CWORD]}") )
                fi
            }
            complete -F _spm_completion spm
            """
        case "fish":
            return "complete -c spm -f -n '__fish_use_subcommand' -a '\(commands)'"
        default:
            throw SPMCommandError.usage("Unsupported shell: \(shell). Choose zsh, bash, or fish.")
        }
    }
}
