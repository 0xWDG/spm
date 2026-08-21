//
//  main.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation
import SPMCore

do {
    try SPM.run(arguments: CommandLine.arguments)
} catch let error as SPMCommandError {
    let message: String
    if SPM.outputOptions.json,
       let data = try? JSONEncoder().encode(SPMOutputRecord(level: "error", message: error.description)),
       let json = String(data: data, encoding: .utf8) {
        message = json
    } else {
        message = error.formattedDescription(colorEnabled: SPM.shouldUseHelpColorsForStandardError())
    }
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(error.exitCode)
} catch {
    FileHandle.standardError.write(Data("Unexpected error: \(error)\n".utf8))
    exit(1)
}
