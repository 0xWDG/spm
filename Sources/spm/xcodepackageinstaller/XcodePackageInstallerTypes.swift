//
//  XcodePackageInstallerTypes.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Errors that can occur while editing an Xcode project for package installation.
public enum XcodePackageInstallerError: Error, CustomStringConvertible {
    /// No `.xcodeproj` file was found.
    case noProjectFound
    /// Multiple `.xcodeproj` files were found.
    case multipleProjectsFound([String])
    /// The project file does not contain a PBXProject object.
    case missingPBXProject
    /// The project file has an unexpected structure.
    case malformedProject(String)
    /// No native target can link package products.
    case noLinkableTarget
    /// A shell command failed.
    case commandFailed(String)

    /// Provides a user-facing error description.
    public var description: String {
        switch self {
        case .noProjectFound:
            return "No .xcodeproj found in the current directory."
        case .multipleProjectsFound(let projects):
            return """
            Multiple .xcodeproj files found. Run this from a directory with exactly one project: \
            \(projects.joined(separator: ", "))
            """
        case .missingPBXProject:
            return "Could not find the PBXProject object in project.pbxproj."
        case .malformedProject(let detail):
            return "Malformed project.pbxproj: \(detail)"
        case .noLinkableTarget:
            return "No PBXNativeTarget with a Frameworks build phase was found."
        case .commandFailed(let detail):
            return detail
        }
    }
}

/// Semantic version parsed from an Xcode package tag.
public struct XcodePackageSemanticVersion {
    /// Major version component.
    public let major: Int
    /// Minor version component.
    public let minor: Int
    /// Patch version component.
    public let patch: Int
    /// Original tag text.
    public let original: String

    /// Creates a semantic version value parsed from an Xcode package tag.
    public init(major: Int, minor: Int, patch: Int, original: String) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.original = original
    }
}

/// Xcode project representation of a package version requirement.
public struct XcodePackageRequirement {
    /// Project-file lines used in the requirement block.
    public let lines: [String]

    /// Creates an Xcode package requirement from project file lines.
    public init(lines: [String]) {
        self.lines = lines
    }
}

/// Decoded package manifest used to discover library products.
public struct XcodePackageManifest: Decodable {
    /// Decoded package product.
    public struct Product: Decodable {
        /// Product name.
        public let name: String
        /// Product type.
        public let type: ProductType

        /// Creates a decoded Swift package product.
        public init(name: String, type: ProductType) {
            self.name = name
            self.type = type
        }
    }

    /// Decoded product type.
    public struct ProductType: Decodable {
        /// Library product payload when the product is a library.
        public let library: [String]?

        /// Creates a decoded Swift package product type.
        public init(library: [String]?) {
            self.library = library
        }
    }

    /// Products declared by the package manifest.
    public let products: [Product]

    /// Creates a decoded Swift package manifest.
    public init(products: [Product]) {
        self.products = products
    }
}

/// Native Xcode target that can receive a Swift package product.
public struct XcodeNativeTarget {
    /// Target object identifier.
    public let id: String
    /// Target display name.
    public let name: String
    /// Frameworks build phase object identifier.
    public let frameworksBuildPhaseID: String

    /// Creates a native target reference from Xcode project object metadata.
    public init(id: String, name: String, frameworksBuildPhaseID: String) {
        self.id = id
        self.name = name
        self.frameworksBuildPhaseID = frameworksBuildPhaseID
    }
}
