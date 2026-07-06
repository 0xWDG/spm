//
//  Configuration.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

public struct SPMConfiguration: Codable {
    public var readme: String?
    public var licence: String?
    public var swiftFileHeader: String?
    public var editorconfig: String?
    public var gitignore: String?
    public var swiftLintRules: String?
    public var name: String?
    public var email: String?
    public var website: String?
    public var github: String?

    /// Creates an SPM configuration.
    public init(
        readme: String? = nil,
        licence: String? = nil,
        swiftFileHeader: String? = nil,
        editorconfig: String? = nil,
        gitignore: String? = nil,
        swiftLintRules: String? = nil,
        name: String? = nil,
        email: String? = nil,
        website: String? = nil,
        github: String? = nil
    ) {
        self.readme = readme
        self.licence = licence
        self.swiftFileHeader = swiftFileHeader
        self.editorconfig = editorconfig
        self.gitignore = gitignore
        self.swiftLintRules = swiftLintRules
        self.name = name
        self.email = email
        self.website = website
        self.github = github
    }

    public var configuredName: String {
        name?.nilIfEmpty ?? "Wesley de Groot"
    }

    public var configuredEmail: String {
        email?.nilIfEmpty ?? "email@WesleydeGroot.nl"
    }

    public var configuredWebsite: String {
        website?.nilIfEmpty ?? "https://wesleydegroot.nl"
    }

    public var configuredgithub: String {
        github?.nilIfEmpty ?? "0xWDG"
    }

    /// Returns a configuration where non-nil values from another configuration override this one.
    public func merged(with overridingConfiguration: SPMConfiguration) -> SPMConfiguration {
        SPMConfiguration(
            readme: overridingConfiguration.readme ?? readme,
            licence: overridingConfiguration.licence ?? licence,
            swiftFileHeader: overridingConfiguration.swiftFileHeader ?? swiftFileHeader,
            editorconfig: overridingConfiguration.editorconfig ?? editorconfig,
            gitignore: overridingConfiguration.gitignore ?? gitignore,
            swiftLintRules: overridingConfiguration.swiftLintRules ?? swiftLintRules,
            name: overridingConfiguration.name ?? name,
            email: overridingConfiguration.email ?? email,
            website: overridingConfiguration.website ?? website,
            github: overridingConfiguration.github ?? github
        )
    }

    /// Sets a configuration value by its command-line key.
    public mutating func set(_ key: String, value: String) throws {
        switch key {
        case "readme":
            readme = value
        case "licence":
            licence = value
        case "swiftFileHeader":
            swiftFileHeader = value
        case "editorconfig":
            editorconfig = value
        case "gitignore":
            gitignore = value
        case "swiftLintRules":
            swiftLintRules = value
        case "name":
            name = value
        case "email":
            email = value
        case "website":
            website = value
        case "github":
            github = value
        default:
            throw ConfigurationError.unknownKey(key)
        }
    }
}

public enum ConfigurationError: Error, CustomStringConvertible {
    case unknownKey(String)

    public var description: String {
        switch self {
        case .unknownKey(let key):
            return "Unknown configuration key: \(key)"
        }
    }
}

public enum ConfigurationScope {
    case local
    case global
}

public let supportedConfigurationKeys = [
    "readme",
    "licence",
    "swiftFileHeader",
    "editorconfig",
    "gitignore",
    "swiftLintRules",
    "name",
    "email",
    "website",
    "github"
]

/// Returns the local project configuration directory.
public func localConfigurationDirectory() -> URL {
    URL(fileURLWithPath: fileManager.currentDirectoryPath)
        .appendingPathComponent(".spm", isDirectory: true)
}

/// Returns the global user configuration directory.
public func globalConfigurationDirectory() -> URL {
    fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent(".config", isDirectory: true)
        .appendingPathComponent("spm", isDirectory: true)
}

/// Returns the configuration directory for the requested scope.
public func configurationDirectory(for scope: ConfigurationScope) -> URL {
    switch scope {
    case .local:
        return localConfigurationDirectory()
    case .global:
        return globalConfigurationDirectory()
    }
}

/// Returns the JSON configuration file URL for the requested scope.
public func configurationFileURL(for scope: ConfigurationScope) -> URL {
    configurationDirectory(for: scope).appendingPathComponent("config.json")
}

/// Reads and decodes a configuration file from disk.
public func readConfiguration(from url: URL) -> SPMConfiguration? {
    guard let data = try? Data(contentsOf: url) else {
        return nil
    }

    return try? JSONDecoder().decode(SPMConfiguration.self, from: data)
}

/// Returns the effective configuration by merging global and local settings.
public func activeConfiguration() -> SPMConfiguration {
    let global = readConfiguration(from: configurationFileURL(for: .global)) ?? SPMConfiguration()
    let local = readConfiguration(from: configurationFileURL(for: .local)) ?? SPMConfiguration()
    return global.merged(with: local)
}

/// Returns the built-in default identity configuration.
public func defaultConfiguration() -> SPMConfiguration {
    SPMConfiguration(
        name: "Wesley de Groot",
        email: "email@WesleydeGroot.nl",
        website: "https://wesleydegroot.nl",
        github: "0xWDG"
    )
}

/// Encodes and writes a configuration file for the requested scope.
public func writeConfiguration(_ configuration: SPMConfiguration, scope: ConfigurationScope) throws {
    let directory = configurationDirectory(for: scope)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(configuration)
    try data.write(to: configurationFileURL(for: scope))
}

/// Creates a configuration file for the requested scope if needed.
public func initializeConfiguration(scope: ConfigurationScope) {
    let existing = readConfiguration(from: configurationFileURL(for: scope)) ?? defaultConfiguration()

    do {
        try writeConfiguration(existing, scope: scope)
        printC("Wrote \(configurationFileURL(for: scope).path)", color: CLIColors.green)
    } catch {
        printC("Failed to write configuration: \(error)", color: CLIColors.red)
        exit(1)
    }
}

/// Prints the effective configuration as formatted JSON.
public func showConfiguration() {
    let configuration = defaultConfiguration().merged(with: activeConfiguration())
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(configuration),
          let json = String(data: data, encoding: .utf8)
    else {
        printC("Failed to encode configuration", color: CLIColors.red)
        exit(1)
    }

    print(json)
}

/// Updates one configuration value in the requested scope.
public func setConfigurationValue(key: String, value: String, scope: ConfigurationScope) {
    var configuration = readConfiguration(from: configurationFileURL(for: scope)) ?? SPMConfiguration()

    do {
        try configuration.set(key, value: value)
        try writeConfiguration(configuration, scope: scope)
        printC("Set \(key) in \(configurationFileURL(for: scope).path)", color: CLIColors.green)
    } catch {
        printC("\(error)", color: CLIColors.red)
        printC("Supported keys: \(supportedConfigurationKeys.joined(separator: ", "))", color: CLIColors.yellow)
        exit(1)
    }
}

/// Resolves configured template content from an inline value, explicit path, or default file names.
public func configurationValueContent(_ value: String?, fileNames: [String]) -> String? {
    let searchDirectories = [
        localConfigurationDirectory(),
        globalConfigurationDirectory()
    ]

    if let value {
        let expandedValue = value.expandingTildeInPath
        let candidateURLs = [
            URL(fileURLWithPath: expandedValue),
            URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(expandedValue)
        ] + searchDirectories.map { $0.appendingPathComponent(value) }

        if let existingURL = candidateURLs.first(where: { fileManager.fileExists(atPath: $0.path) }),
           let content = try? String(contentsOf: existingURL, encoding: .utf8) {
            return content
        }

        return value
    }

    for directory in searchDirectories {
        for fileName in fileNames {
            let url = directory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: url.path),
               let content = try? String(contentsOf: url, encoding: .utf8) {
                return content
            }
        }
    }

    return nil
}

/// Replaces supported placeholders in a template with package and configuration values.
public func renderTemplate(_ template: String, configuration: SPMConfiguration, filename: String? = nil) -> String {
    let replacements = [
        "PACKAGENAME": productName,
        "{{packageName}}": productName,
        "{{filename}}": filename ?? "",
        "{{name}}": configuration.configuredName,
        "{{email}}": configuration.configuredEmail,
        "{{website}}": configuration.configuredWebsite,
        "{{github}}": configuration.configuredgithub,
        "{{year}}": String(Calendar.current.component(.year, from: Date()))
    ]

    return replacements.reduce(template) { result, replacement in
        result.replacingOccurrences(of: replacement.key, with: replacement.value)
    }
}

public extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var expandingTildeInPath: String {
        NSString(string: self).expandingTildeInPath
    }
}
