//
//  NativeTargets.swift
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
/// Extracts native targets that can link Swift package products.
static func nativeTargets(inXcodeProject project: String) -> [XcodeNativeTarget] {
    xcodeObjectRanges(containing: "isa = PBXNativeTarget;", in: project).compactMap { range in
        let object = String(project[range])
        guard let id = xcodeObjectID(from: object) else { return nil }
        let name = xcodeObjectComment(from: object) ?? id
        guard
            let buildPhasesRange = xcodeListBlockRange(named: "buildPhases", in: object),
            let frameworksLine = object[buildPhasesRange]
                .split(separator: "\n")
                .first(where: { $0.contains("/* Frameworks */") }),
            let phaseID = frameworksLine
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
                .first
                .map(String.init)
        else {
            return nil
        }

        return XcodeNativeTarget(
            id: id,
            name: name,
            frameworksBuildPhaseID: phaseID
        )
    }
}
}
