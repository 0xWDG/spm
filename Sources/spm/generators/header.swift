//
//  header.swift
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
/// Updates Swift file headers using configured or built-in header templates.
static func header() {
    let configuration = activeConfiguration()
    let enumerator = fileManager.enumerator(atPath: ".")
    while let element = enumerator?.nextObject() as? String {
        if [".build", ".git", ".spm", ".swiftpm"].contains(element) {
            enumerator?.skipDescendants()
            continue
        }

        if element.hasSuffix(".swift") {
            updateHeader(for: element, configuration: configuration)
        }
    }
}

/// Updates the header for one Swift source file.
static func updateHeader(for file: String, configuration: SPMConfiguration) {
    let path = URL(fileURLWithPath: file)
    guard let contents = try? String(contentsOf: path, encoding: .utf8) else {
        printC("Failed to read \(file)", color: CLIColors.red)
        return
    }

    let filename = file.components(separatedBy: "/").last
    var lines = contents.components(separatedBy: .newlines)
    guard let firstLine = lines.first, !firstLine.hasPrefix("#!"), file != "Package.swift" else {
        return
    }

    let headerLineCount = existingHeaderLineCount(in: lines)
    let createdBy = existingCreatedByLine(in: lines) ?? defaultCreatedByLine(configuration: configuration)
    lines.removeFirst(headerLineCount)
    lines.insert(contentsOf: headerLines(for: filename, createdBy: createdBy, configuration: configuration), at: 0)

    do {
        try lines.joined(separator: "\n").write(to: path, atomically: true, encoding: .utf8)
        printC("Updated header for \(file)", color: CLIColors.green)
    } catch {
        printC("Failed to update header for \(file)", color: CLIColors.red)
    }
}

/// Counts the current file header comment lines.
static func existingHeaderLineCount(in lines: [String]) -> Int {
    lines.prefix { $0.hasPrefix("//") }.count
}

/// Returns the existing Created by line, when present.
static func existingCreatedByLine(in lines: [String]) -> String? {
    lines.prefix { $0.hasPrefix("//") }.first { $0.contains("Created by") }
}

/// Builds a default Created by line.
static func defaultCreatedByLine(configuration: SPMConfiguration) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let date = dateFormatter.string(from: Date())
    return "//  Created by \(configuration.configuredName) on \(date)."
}

/// Returns rendered header lines for a Swift file.
static func headerLines(
    for filename: String?,
    createdBy: String,
    configuration: SPMConfiguration
) -> [String] {
    let headerTemplate = configurationValueContent(
        configuration.swiftFileHeader,
        fileNames: ["HEADER.swift", "Header.swift", "header.swift", ".swiftfile"]
    )
    let renderedHeader = headerTemplate.map {
        renderTemplate($0, configuration: configuration, filename: filename)
    }

    return renderedHeader?.components(separatedBy: .newlines) ?? defaultHeaderLines(
        for: filename,
        createdBy: createdBy,
        configuration: configuration
    )
}

/// Returns built-in header lines for a Swift file.
static func defaultHeaderLines(
    for filename: String?,
    createdBy: String,
    configuration: SPMConfiguration
) -> [String] {
    [
        "//",
        "//  \(filename ?? "")",
        "//  \(productName)",
        "//",
        createdBy,
        "//  \(configuration.configuredWebsite)",
        "//",
        "//  https://github.com/\(configuration.configuredgithub)/\(productName)",
        "//  MIT License",
        "//"
    ]
}
}
