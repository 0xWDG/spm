//
//  SPMRuntime.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Runtime dependencies used by package operations.
public struct SPMRuntime: @unchecked Sendable {
    /// Filesystem implementation used by commands.
    public let fileManager: FileManager
    /// Root directory used to resolve project-relative paths.
    public let workingDirectory: URL
    /// Environment values used by commands and diagnostics.
    public let environment: [String: String]

    /// Creates an injectable command runtime.
    public init(
        fileManager: FileManager = .default,
        workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.workingDirectory = workingDirectory.standardizedFileURL
        self.environment = environment
    }

    /// Runtime for the current command.
    nonisolated(unsafe) public static var current = SPMRuntime()
}

public extension SPM {
    /// Executes an operation with an injected runtime and restores the previous runtime afterward.
    static func withRuntime<T>(_ runtime: SPMRuntime, operation: () throws -> T) rethrows -> T {
        let previous = SPMRuntime.current
        SPMRuntime.current = runtime
        defer { SPMRuntime.current = previous }
        return try operation()
    }

    /// Resolves a project-relative path against the active working directory.
    static func projectURL(_ path: String = "") -> URL {
        guard !path.isEmpty else { return SPMRuntime.current.workingDirectory }
        return SPMRuntime.current.workingDirectory.appendingPathComponent(path)
    }
}
