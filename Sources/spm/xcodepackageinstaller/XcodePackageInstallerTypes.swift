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

public enum XcodePackageInstallerError: Error, CustomStringConvertible {
    case noProjectFound
    case multipleProjectsFound([String])
    case missingPBXProject
    case malformedProject(String)
    case noLinkableTarget
    case commandFailed(String)

    /// Provides a user-facing error description.
    public var description: String {
        switch self {
        case .noProjectFound:
            return "No .xcodeproj found in the current directory."
        case .multipleProjectsFound(let projects):
            return "Multiple .xcodeproj files found. Run this from a directory with exactly one project: \(projects.joined(separator: ", "))"
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

public struct XcodePackageSemanticVersion: Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let original: String

    /// Creates a semantic version value parsed from an Xcode package tag.
    public init(major: Int, minor: Int, patch: Int, original: String) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.original = original
    }

    /// Compares semantic versions by major, minor, and patch components.
    public static func < (lhs: XcodePackageSemanticVersion, rhs: XcodePackageSemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

public struct XcodePackageRequirement {
    public let lines: [String]

    /// Creates an Xcode package requirement from project file lines.
    public init(lines: [String]) {
        self.lines = lines
    }
}

public struct XcodePackageManifest: Decodable {
    public struct Product: Decodable {
        public let name: String
        public let type: ProductType

        /// Creates a decoded Swift package product.
        public init(name: String, type: ProductType) {
            self.name = name
            self.type = type
        }
    }

    public struct ProductType: Decodable {
        public let library: [String]?

        /// Creates a decoded Swift package product type.
        public init(library: [String]?) {
            self.library = library
        }
    }

    public let products: [Product]

    /// Creates a decoded Swift package manifest.
    public init(products: [Product]) {
        self.products = products
    }
}

public struct XcodeNativeTarget {
    public let id: String
    public let name: String
    public let frameworksBuildPhaseID: String

    /// Creates a native target reference from Xcode project object metadata.
    public init(id: String, name: String, frameworksBuildPhaseID: String) {
        self.id = id
        self.name = name
        self.frameworksBuildPhaseID = frameworksBuildPhaseID
    }
}
