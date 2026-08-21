//
//  ProcessRunner.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Result from a completed child process.
public struct ProcessResult: Sendable {
    /// Child process exit status.
    public let status: Int32
    /// Captured standard output.
    public let standardOutput: String
    /// Captured standard error.
    public let standardError: String
}

private final class ProcessDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ additionalData: Data) {
        lock.lock()
        data.append(additionalData)
        lock.unlock()
    }

    func value() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

/// Runs child processes with concurrent output draining and optional timeouts.
public struct ProcessRunner: Sendable {
    /// Creates a process runner.
    public init() {}

    /// Runs a child process and captures its output.
    public func run(
        executable: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        environment: [String: String]? = nil,
        timeout: TimeInterval = 120
    ) throws -> ProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let outputBuffer = ProcessDataBuffer()
        let errorBuffer = ProcessDataBuffer()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.environment = environment
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            outputBuffer.append(handle.availableData)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            errorBuffer.append(handle.availableData)
        }

        do {
            try process.run()
        } catch {
            throw SPMCommandError.failure("Failed to run \(executable): \(error)", exitCode: 1)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }

        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            throw SPMCommandError.failure(
                "Command timed out after \(Int(timeout)) seconds: \(executable)",
                exitCode: 124
            )
        }

        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        outputBuffer.append(outputPipe.fileHandleForReading.readDataToEndOfFile())
        errorBuffer.append(errorPipe.fileHandleForReading.readDataToEndOfFile())
        return ProcessResult(
            status: process.terminationStatus,
            standardOutput: String(data: outputBuffer.value(), encoding: .utf8) ?? "",
            standardError: String(data: errorBuffer.value(), encoding: .utf8) ?? ""
        )
    }
}
