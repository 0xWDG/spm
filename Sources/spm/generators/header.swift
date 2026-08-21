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

/// Scope and safety options for header updates.
public struct HeaderCommandOptions: Equatable {
    /// Shared overwrite behavior.
    public let overwrite: OverwriteOptions
    /// Included path prefixes; empty means all project Swift files.
    public let includes: [String]
    /// Excluded path prefixes.
    public let excludes: [String]
}

public extension SPM {
/// Updates Swift file headers using configured or built-in header templates.
static func header(options: OverwriteOptions = OverwriteOptions()) throws {
    try header(commandOptions: HeaderCommandOptions(overwrite: options, includes: [], excludes: []))
}

/// Updates Swift headers within an explicitly selected path scope.
static func header(commandOptions: HeaderCommandOptions) throws {
    let options = commandOptions.overwrite
    _ = try requiredProductName()
    guard options.force || options.dryRun || options.diff else {
        throw SPMCommandError.usage(
            "Refusing to replace Swift file headers. Pass --force to update them or --dry-run to preview."
        )
    }

    let configuration = try activeConfiguration()
    let enumerator = fileManager.enumerator(atPath: projectURL().path)
    while let element = enumerator?.nextObject() as? String {
        if [".build", ".git", ".spm", ".swiftpm"].contains(element) {
            enumerator?.skipDescendants()
            continue
        }

        let included = commandOptions.includes.isEmpty || commandOptions.includes.contains {
            element == $0 || element.hasPrefix("\($0)/")
        }
        let excluded = commandOptions.excludes.contains {
            element == $0 || element.hasPrefix("\($0)/")
        }
        if element.hasSuffix(".swift") && included && !excluded {
            try updateHeader(for: element, configuration: configuration, options: options)
        }
    }
}

/// Parses header include, exclude, force, and preview options.
static func headerCommandOptions(from arguments: [String]) throws -> HeaderCommandOptions {
    var includes: [String] = []
    var excludes: [String] = []
    var overwriteArguments: [String] = []
    var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--include", "--exclude":
            guard index + 1 < arguments.count else {
                throw SPMCommandError.usage("Missing path for \(arguments[index]).")
            }
            let value = arguments[index + 1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if arguments[index] == "--include" { includes.append(value) } else { excludes.append(value) }
            index += 2
        default:
            overwriteArguments.append(arguments[index])
            index += 1
        }
    }
    return HeaderCommandOptions(
        overwrite: try overwriteOptions(from: overwriteArguments),
        includes: includes,
        excludes: excludes
    )
}

/// Updates the header for one Swift source file.
static func updateHeader(
    for file: String,
    configuration: SPMConfiguration,
    options: OverwriteOptions
) throws {
    let path = projectURL(file)
    let contents: String
    do {
        contents = try String(contentsOf: path, encoding: .utf8)
    } catch {
        throw SPMCommandError.failure("Failed to read \(file): \(error)", exitCode: 1)
    }

    let filename = file.components(separatedBy: "/").last
    var lines = contents.components(separatedBy: .newlines)
    guard let firstLine = lines.first, !firstLine.hasPrefix("#!"), file != "Package.swift" else {
        return
    }

    let headerLineCount = existingHeaderLineCount(in: lines)
    let createdBy = existingCreatedByLine(in: lines) ?? defaultCreatedByLine(configuration: configuration)
    lines.removeFirst(headerLineCount)
    lines.insert(
        contentsOf: try headerLines(for: filename, createdBy: createdBy, configuration: configuration),
        at: 0
    )

    try writeGeneratedFile(lines.joined(separator: "\n"), to: path, options: options)
    if !options.dryRun {
        printC("Updated header for \(file)", color: CLIColors.green)
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
) throws -> [String] {
    let headerTemplate = try configurationValueContent(
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
