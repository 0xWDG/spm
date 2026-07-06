//
//  gitIgnore.swift
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
/// Generates a .gitignore file from configured or built-in ignore rules.
static func generateGitIgnore() {
    let configuration = activeConfiguration()
    let gitIgnore = renderTemplate(
        configurationValueContent(
            configuration.gitignore,
            fileNames: ["gitignore", ".gitignore"]
        ) ?? defaultGitIgnoreTemplate,
        configuration: configuration
    )

    do {
        try gitIgnore.write(to: URL(fileURLWithPath: ".gitignore"), atomically: true, encoding: .utf8)
        printC("Generated .gitignore", color: CLIColors.green)
    } catch {
        printC("Failed to generate .gitignore", color: CLIColors.red)
    }
}

/// Built-in .gitignore template.
static var defaultGitIgnoreTemplate: String {
    """
    ## User settings
    xcuserdata/

    ## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
    *.xcscmblueprint
    *.xccheckout

    ## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
    build/
    DerivedData/
    *.moved-aside
    *.pbxuser
    !default.pbxuser
    *.mode1v3
    !default.mode1v3
    *.mode2v3
    !default.mode2v3
    *.perspectivev3
    !default.perspectivev3

    ## Obj-C/Swift specific
    *.hmap

    ## App packaging
    *.ipa
    *.dSYM.zip
    *.dSYM

    ## Playgrounds
    timeline.xctimeline
    playground.xcworkspace

    ### Swift Package Manager
    Packages/
    Package.pins
    Package.resolved
    # *.xcodeproj
    #
    # Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
    # hence it is not needed unless you have added a package configuration file to your project
    .swiftpm
    .build/

    ### CocoaPods
    Pods/
    *.xcworkspace

    ### Carthage
    Carthage/Checkouts
    Carthage/Build/

    ### Accio dependency management
    Dependencies/
    .accio/

    ### fastlane
    fastlane/report.xml
    fastlane/Preview.html
    fastlane/screenshots/**/*.png
    fastlane/test_output

    ### Code Injection
    iOSInjectionProject/
    """
}
}
