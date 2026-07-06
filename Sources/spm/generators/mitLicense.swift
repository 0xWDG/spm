//
//  mitLicense.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public extension spm {
/// Generates a LICENCE.md file from configured or built-in license content.
static func generateMITLicense() {
    let configuration = activeConfiguration()
    let license = renderTemplate(
        configurationValueContent(
            configuration.licence,
            fileNames: ["LICENCE.md", "LICENSE.md"]
        ) ?? defaultMITLicense(configuration: configuration),
        configuration: configuration
    )

    do {
        try license.write(to: URL(fileURLWithPath: "LICENCE.md"), atomically: true, encoding: .utf8)
        printC("Generated LICENCE.md", color: CLIColors.green)
    } catch {
        printC("Failed to generate LICENCE.md", color: CLIColors.red)
    }
}

/// Returns the built-in MIT licence template.
static func defaultMITLicense(configuration: SPMConfiguration) -> String {
    let year = Calendar.current.component(.year, from: Date())
    let copyright = "Copyright (c) \(year) \(configuration.configuredName), \(configuration.configuredEmail)"
    let permission = [
        "Permission is hereby granted, free of charge, to any person obtaining a copy of this software",
        "and associated documentation files (the \"Software\"), to deal in the Software without",
        "restriction, including without limitation the rights to use, copy, modify, merge, publish,",
        "distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom",
        "the Software is furnished to do so, subject to the following conditions:"
    ].joined(separator: " ")
    let warranty = [
        "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,",
        "INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR",
        "PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE",
        "FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR",
        "OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER",
        "DEALINGS IN THE SOFTWARE."
    ].joined(separator: " ")

    return [
        "MIT License",
        copyright,
        permission,
        [
            "The above copyright notice and this permission notice shall be included in all copies",
            "or substantial portions of the Software."
        ].joined(separator: " "),
        warranty
    ].joined(separator: "\n\n") + "\n"
}
}
