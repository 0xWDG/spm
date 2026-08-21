//
//  spmTests.swift
//  spm
//
//  Created by Wesley de Groot on 2026-08-21.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation
import Testing
@testable import SPMCore

@Suite("Package metadata parsing")
struct PackageMetadataTests {
    @Test("Extracts a package name from a manifest")
    func extractsPackageName() {
        let manifest = #"let package = Package(name: "ExampleKit")"#

        #expect(SPM.packageName(from: manifest) == "ExampleKit")
    }

    @Test("Parses common semantic version tags")
    func parsesSemanticVersions() {
        let version = SPM.parseXcodePackageSemanticVersion("refs/tags/v2.4.1")

        #expect(version?.major == 2)
        #expect(version?.minor == 4)
        #expect(version?.patch == 1)
        #expect(version?.original == "2.4.1")
        #expect(SPM.parseXcodePackageSemanticVersion("latest") == nil)
    }

    @Test("Derives a package name from HTTPS and SSH URLs", arguments: [
        ("https://github.com/apple/swift-collections.git", "swift-collections"),
        ("git@github.com:apple/swift-collections.git", "swift-collections")
    ])
    func derivesPackageName(url: String, expectedName: String) {
        #expect(SPM.swiftPackageName(from: url) == expectedName)
    }
}

@Suite("Package input normalization")
struct PackageInputNormalizationTests {
    @Test("Expands supported package shorthand", arguments: [
        ("apple/swift-collections", "https://github.com/apple/swift-collections"),
        ("github.com/apple/swift-collections", "https://github.com/apple/swift-collections"),
        ("swift-collections", "https://github.com/0xWDG/swift-collections"),
        ("https://example.com/package.git", "https://example.com/package.git")
    ])
    func expandsShorthand(input: String, expectedURL: String) {
        #expect(SPM.normalizedSwiftPackageURL(from: input) == expectedURL)
    }

    @Test("Builds PascalCase product name candidates")
    func buildsProductNameCandidates() {
        let candidates = Set(SPM.possibleSwiftPackageProductNames(from: "swift-argument-parser"))

        #expect(candidates.contains("swift-argument-parser"))
        #expect(candidates.contains("argument-parser"))
        #expect(candidates.contains("SwiftArgumentParser"))
        #expect(candidates.contains("ArgumentParser"))
    }
}

@Suite("Command safety")
struct CommandSafetyTests {
    @Test("Help colors preserve semantic labels")
    func helpColorsPreserveLabels() {
        let plain = SPM.helpText(executable: "/usr/local/bin/spm", colorEnabled: false)
        let colored = SPM.helpText(executable: "/usr/local/bin/spm", colorEnabled: true)

        #expect(!plain.contains("\u{001B}"))
        #expect(colored.contains(CLIColors.cyan))
        #expect(colored.contains(CLIColors.green))
        #expect(colored.contains("Usage:"))
        #expect(colored.contains("Commands:"))
        #expect(colored.contains("--dry-run"))
    }

    @Test("Help color policy respects terminal environment", arguments: [
        (["NO_COLOR": ""], true, false),
        (["FORCE_COLOR": "1"], false, true),
        (["FORCE_COLOR": "0"], true, false),
        ([:], true, true),
        ([:], false, false)
    ])
    func helpColorPolicy(environment: [String: String], isTerminal: Bool, expected: Bool) {
        #expect(SPM.shouldUseHelpColors(environment: environment, isTerminal: isTerminal) == expected)
    }

    @Test("Missing commands return a usage error instead of terminating")
    func missingCommandThrowsUsageError() {
        do {
            try SPM.run(arguments: ["spm"])
            Issue.record("Expected a usage error")
        } catch let error as SPMCommandError {
            #expect(error.exitCode == 2)
            #expect(error.description.contains("Usage: spm"))
            #expect(error.formattedDescription(colorEnabled: true).contains(CLIColors.cyan))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Generator options reject unsupported arguments")
    func rejectsUnknownGeneratorOption() {
        #expect(throws: SPMCommandError.self) {
            try SPM.overwriteOptions(from: ["--replace"])
        }
    }

    @Test("Generated files require force and support dry runs")
    func generatedFilesUseSafeOverwriteRules() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("spm-tests-\(UUID().uuidString)", isDirectory: true)
        let destination = directory.appendingPathComponent("README.md")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try "original".write(to: destination, atomically: true, encoding: .utf8)

        #expect(throws: SPMCommandError.self) {
            try SPM.writeGeneratedFile("replacement", to: destination, options: OverwriteOptions())
        }
        #expect(try String(contentsOf: destination, encoding: .utf8) == "original")

        try SPM.writeGeneratedFile(
            "replacement",
            to: destination,
            options: OverwriteOptions(dryRun: true)
        )
        #expect(try String(contentsOf: destination, encoding: .utf8) == "original")

        try SPM.writeGeneratedFile(
            "replacement",
            to: destination,
            options: OverwriteOptions(force: true)
        )
        #expect(try String(contentsOf: destination, encoding: .utf8) == "replacement")
    }
}

@Suite("Swift tools version policy")
struct SwiftToolsVersionPolicyTests {
    @Test("Package manifests use the Swift 6 baseline")
    func updatesPackageToolsVersion() {
        let manifest = """
        // swift-tools-version: 5.8
        import PackageDescription
        let package = Package(name: "Example")
        """

        let updated = SPM.packageBySettingToolsVersion(manifest)

        #expect(updated.hasPrefix("// swift-tools-version: 6.0\n"))
        #expect(updated.contains("let package = Package(name: \"Example\")"))
    }
}

@Suite("Expanded command features")
struct ExpandedCommandFeatureTests {
    @Test("Central version is used by help")
    func helpUsesCentralVersion() {
        #expect(SPM.usage().contains("v\(SPMVersion.current)"))
    }

    @Test("Global output options can appear anywhere")
    func parsesGlobalOutputOptions() {
        let parsed = SPM.extractOutputOptions(
            from: ["spm", "build", "--json", "--quiet", "--native", "--no-color"]
        )

        #expect(parsed.arguments == ["spm", "build", "--native"])
        #expect(parsed.options == SPMOutputOptions(json: true, quiet: true, noColor: true))
    }

    @Test("Build options support platform and destination selection")
    func parsesBuildOptions() throws {
        let options = try SPM.buildOptions(from: [
            "--platform", "macOS,iOS",
            "--configuration", "release",
            "--scheme", "Example",
            "--destination", "platform=iOS Simulator",
            "--native"
        ])

        #expect(options.platforms == ["macOS", "iOS"])
        #expect(options.configuration == "release")
        #expect(options.scheme == "Example")
        #expect(options.destination == "platform=iOS Simulator")
        #expect(options.native)
    }

    @Test("Header options support repeatable path filters")
    func parsesHeaderFilters() throws {
        let options = try SPM.headerCommandOptions(from: [
            "--force", "--include", "Sources/", "--include", "Tests", "--exclude", "Sources/Generated"
        ])

        #expect(options.overwrite.force)
        #expect(options.includes == ["Sources", "Tests"])
        #expect(options.excludes == ["Sources/Generated"])
    }

    @Test("Completion scripts cover supported shells", arguments: ["zsh", "bash", "fish"])
    func generatesCompletion(shell: String) throws {
        let script = try SPM.completionScript(for: shell)

        #expect(script.contains("spm"))
        #expect(script.contains("uninstall"))
        #expect(script.contains("doctor"))
    }

    @Test("Diff previews contain both versions")
    func createsReadableDiff() {
        let diff = SPM.unifiedDiff(original: "first\nold", updated: "first\nnew", path: "Example.swift")

        #expect(diff.contains("--- a/Example.swift"))
        #expect(diff.contains("-old"))
        #expect(diff.contains("+new"))
    }

    @Test("Configuration fields can be unset")
    func clearsConfigurationField() throws {
        var configuration = SPMConfiguration(name: "Example", email: "hello@example.com")

        try SPM.clearConfigurationField(&configuration, key: "name")

        #expect(configuration.name == nil)
        #expect(configuration.email == "hello@example.com")
    }

    @Test("File transactions replace all requested files")
    func appliesFileTransaction() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("spm-transaction-\(UUID().uuidString)", isDirectory: true)
        let first = directory.appendingPathComponent("first.txt")
        let second = directory.appendingPathComponent("second.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("before".utf8).write(to: first)

        try SPM.applyFileTransaction([
            FileChange(url: first, data: Data("after".utf8)),
            FileChange(url: second, data: Data("created".utf8))
        ])

        #expect(try String(contentsOf: first, encoding: .utf8) == "after")
        #expect(try String(contentsOf: second, encoding: .utf8) == "created")
    }

    @Test("Process runner drains standard output and error")
    func drainsProcessOutput() throws {
        let result = try ProcessRunner().run(
            executable: "/bin/sh",
            arguments: ["-c", "echo standard-output; echo standard-error >&2"]
        )

        #expect(result.status == 0)
        #expect(result.standardOutput.contains("standard-output"))
        #expect(result.standardError.contains("standard-error"))
    }

    @Test("Process runner enforces timeouts")
    func enforcesProcessTimeout() {
        do {
            _ = try ProcessRunner().run(
                executable: "/bin/sh",
                arguments: ["-c", "while :; do :; done"],
                timeout: 0.05
            )
            Issue.record("Expected the process to time out")
        } catch let error as SPMCommandError {
            #expect(error.exitCode == 124)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Package uninstall removes related Xcode objects and list entries")
    func removesXcodePackageObjects() throws {
        let project = """
        PACKAGE = {
            isa = XCRemoteSwiftPackageReference;
            repositoryURL = "https://github.com/apple/swift-collections";
        };
        PRODUCT = {
            isa = XCSwiftPackageProductDependency;
            package = PACKAGE;
            productName = Collections;
        };
        BUILD = {
            isa = PBXBuildFile;
            productRef = PRODUCT;
        };
        packageReferences = (
            PACKAGE /* XCRemoteSwiftPackageReference \"swift-collections\" */,
        );
        packageProductDependencies = (
            PRODUCT /* Collections */,
        );
        files = (
            BUILD /* Collections in Frameworks */,
        );
        """
        let reference = try #require(SPM.packageReference(in: project, matching: "swift-collections"))

        let updated = SPM.removePackageReference(reference, from: project)

        #expect(!updated.contains("PACKAGE"))
        #expect(!updated.contains("PRODUCT"))
        #expect(!updated.contains("BUILD"))
    }
}
