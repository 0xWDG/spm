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

/// Stored JSON configuration for generated package files and author metadata.
public struct SPMConfiguration: Codable {
    /// Custom README content or a path to a README template.
    public var readme: String?
    /// Custom LICENCE content or a path to a licence template.
    public var licence: String?
    /// Custom Swift file header content or a path to a header template.
    public var swiftFileHeader: String?
    /// Custom .editorconfig content or a path to a template.
    public var editorconfig: String?
    /// Custom .gitignore content or a path to a template.
    public var gitignore: String?
    /// Custom SwiftLint rules or a path to a template.
    public var swiftLintRules: String?
    /// Author name used in headers and licence templates.
    public var name: String?
    /// Author email used in licence templates.
    public var email: String?
    /// Website used in generated templates.
    public var website: String?
    /// GitHub username used in generated templates.
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

    /// Author name with the built-in default applied.
    public var configuredName: String {
        name?.nilIfEmpty ?? "Wesley de Groot"
    }

    /// Author email with the built-in default applied.
    public var configuredEmail: String {
        email?.nilIfEmpty ?? "email@WesleydeGroot.nl"
    }

    /// Website with the built-in default applied.
    public var configuredWebsite: String {
        website?.nilIfEmpty ?? "https://wesleydegroot.nl"
    }

    /// GitHub username with the built-in default applied.
    public var configuredgithub: String {
        github?.nilIfEmpty ?? "0xWDG"
    }

}

/// Errors raised while reading or updating configuration.
public enum ConfigurationError: Error, CustomStringConvertible {
    /// A requested configuration key is not supported.
    case unknownKey(String)

    /// Human-readable error description.
    public var description: String {
        switch self {
        case .unknownKey(let key):
            return "Unknown configuration key: \(key)"
        }
    }
}

/// Defines whether configuration is stored locally or globally.
public enum ConfigurationScope {
    /// Project-local configuration in `.spm/config.json`.
    case local
    /// User-global configuration in `~/.config/spm/config.json`.
    case global
}

/// Supported command-line configuration keys.
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

private let configurationKeyPaths: [String: WritableKeyPath<SPMConfiguration, String?>] = [
    "readme": \.readme,
    "licence": \.licence,
    "swiftFileHeader": \.swiftFileHeader,
    "editorconfig": \.editorconfig,
    "gitignore": \.gitignore,
    "swiftLintRules": \.swiftLintRules,
    "name": \.name,
    "email": \.email,
    "website": \.website,
    "github": \.github
]

public extension spm {
/// Returns the local project configuration directory.
static func localConfigurationDirectory() -> URL {
    URL(fileURLWithPath: fileManager.currentDirectoryPath)
        .appendingPathComponent(".spm", isDirectory: true)
}

/// Returns the global user configuration directory.
static func globalConfigurationDirectory() -> URL {
    fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent(".config", isDirectory: true)
        .appendingPathComponent("spm", isDirectory: true)
}

/// Returns the configuration directory for the requested scope.
static func configurationDirectory(for scope: ConfigurationScope) -> URL {
    switch scope {
    case .local:
        return localConfigurationDirectory()
    case .global:
        return globalConfigurationDirectory()
    }
}

/// Returns the JSON configuration file URL for the requested scope.
static func configurationFileURL(for scope: ConfigurationScope) -> URL {
    configurationDirectory(for: scope).appendingPathComponent("config.json")
}

/// Reads and decodes a configuration file from disk.
static func readConfiguration(from url: URL) -> SPMConfiguration? {
    guard let data = try? Data(contentsOf: url) else {
        return nil
    }

    return try? JSONDecoder().decode(SPMConfiguration.self, from: data)
}

/// Returns the effective configuration by merging global and local settings.
static func activeConfiguration() -> SPMConfiguration {
    let global = readConfiguration(from: configurationFileURL(for: .global)) ?? SPMConfiguration()
    let local = readConfiguration(from: configurationFileURL(for: .local)) ?? SPMConfiguration()
    return mergedConfiguration(global, with: local)
}

/// Returns the built-in default identity configuration.
static func defaultConfiguration() -> SPMConfiguration {
    SPMConfiguration(
        name: "Wesley de Groot",
        email: "email@WesleydeGroot.nl",
        website: "https://wesleydegroot.nl",
        github: "0xWDG"
    )
}

/// Returns a configuration where non-nil values from another configuration override the base configuration.
static func mergedConfiguration(
    _ configuration: SPMConfiguration,
    with overridingConfiguration: SPMConfiguration
) -> SPMConfiguration {
    SPMConfiguration(
        readme: overridingConfiguration.readme ?? configuration.readme,
        licence: overridingConfiguration.licence ?? configuration.licence,
        swiftFileHeader: overridingConfiguration.swiftFileHeader ?? configuration.swiftFileHeader,
        editorconfig: overridingConfiguration.editorconfig ?? configuration.editorconfig,
        gitignore: overridingConfiguration.gitignore ?? configuration.gitignore,
        swiftLintRules: overridingConfiguration.swiftLintRules ?? configuration.swiftLintRules,
        name: overridingConfiguration.name ?? configuration.name,
        email: overridingConfiguration.email ?? configuration.email,
        website: overridingConfiguration.website ?? configuration.website,
        github: overridingConfiguration.github ?? configuration.github
    )
}

/// Sets a configuration value by its command-line key.
static func setConfigurationField(_ configuration: inout SPMConfiguration, key: String, value: String) throws {
    guard let keyPath = configurationKeyPaths[key] else {
        throw ConfigurationError.unknownKey(key)
    }

    configuration[keyPath: keyPath] = value
}

/// Encodes and writes a configuration file for the requested scope.
static func writeConfiguration(_ configuration: SPMConfiguration, scope: ConfigurationScope) throws {
    let directory = configurationDirectory(for: scope)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(configuration)
    try data.write(to: configurationFileURL(for: scope))
}

/// Creates a configuration file for the requested scope if needed.
static func initializeConfiguration(scope: ConfigurationScope) {
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
static func showConfiguration() {
    let configuration = mergedConfiguration(defaultConfiguration(), with: activeConfiguration())
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
static func setConfigurationValue(key: String, value: String, scope: ConfigurationScope) {
    var configuration = readConfiguration(from: configurationFileURL(for: scope)) ?? SPMConfiguration()

    do {
        try setConfigurationField(&configuration, key: key, value: value)
        try writeConfiguration(configuration, scope: scope)
        printC("Set \(key) in \(configurationFileURL(for: scope).path)", color: CLIColors.green)
    } catch {
        printC("\(error)", color: CLIColors.red)
        printC("Supported keys: \(supportedConfigurationKeys.joined(separator: ", "))", color: CLIColors.yellow)
        exit(1)
    }
}

/// Resolves configured template content from an inline value, explicit path, or default file names.
static func configurationValueContent(_ value: String?, fileNames: [String]) -> String? {
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
static func renderTemplate(_ template: String, configuration: SPMConfiguration, filename: String? = nil) -> String {
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

}

public extension String {
    /// Returns nil when the string is empty.
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    /// Expands a leading tilde in a filesystem path.
    var expandingTildeInPath: String {
        NSString(string: self).expandingTildeInPath
    }
}
