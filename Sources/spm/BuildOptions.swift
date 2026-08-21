//
//  BuildOptions.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Options controlling package builds.
public struct BuildOptions: Equatable {
    /// Explicit Apple platforms to build.
    public let platforms: [String]
    /// Debug or release build configuration.
    public let configuration: String
    /// Xcode scheme override.
    public let scheme: String?
    /// Xcode destination override.
    public let destination: String?
    /// Uses `swift build` instead of Xcode platform builds.
    public let native: Bool

    /// Creates build options.
    public init(
        platforms: [String] = [],
        configuration: String = "debug",
        scheme: String? = nil,
        destination: String? = nil,
        native: Bool = false
    ) {
        self.platforms = platforms
        self.configuration = configuration
        self.scheme = scheme
        self.destination = destination
        self.native = native
    }
}

public extension SPM {
    /// Parses build command options.
    static func buildOptions(from arguments: [String]) throws -> BuildOptions {
        var platforms: [String] = []
        var configuration = "debug"
        var scheme: String?
        var destination: String?
        var native = false
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            switch option {
            case "--platform":
                platforms += try optionValue(arguments, index: &index, option: option)
                    .split(separator: ",").map(String.init)
            case "--configuration", "-c":
                configuration = try optionValue(arguments, index: &index, option: option).lowercased()
            case "--scheme":
                scheme = try optionValue(arguments, index: &index, option: option)
            case "--destination":
                destination = try optionValue(arguments, index: &index, option: option)
            case "--native":
                native = true
                index += 1
            default:
                throw SPMCommandError.usage("Unknown build option: \(option)")
            }
        }
        guard ["debug", "release"].contains(configuration) else {
            throw SPMCommandError.usage("Build configuration must be debug or release.")
        }
        return BuildOptions(
            platforms: platforms,
            configuration: configuration,
            scheme: scheme,
            destination: destination,
            native: native
        )
    }

    /// Reads an option value and advances a parser index.
    static func optionValue(_ arguments: [String], index: inout Int, option: String) throws -> String {
        guard index + 1 < arguments.count else {
            throw SPMCommandError.usage("Missing value for \(option).")
        }
        let value = arguments[index + 1]
        index += 2
        return value
    }
}
