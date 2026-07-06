//
//  header.swift
//  spm
//
//  Created by Wesley de Groot on 2026-07-06.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/spm
//  MIT License
//

import Foundation

/// Updates Swift file headers using configured or built-in header templates.
public func header() {
    let configuration = activeConfiguration()
    let enumerator = fileManager.enumerator(atPath: ".")
    while let element = enumerator?.nextObject() as? String {
        if [".build", ".git", ".spm", ".swiftpm"].contains(element) {
            enumerator?.skipDescendants()
            continue
        }

        if element.hasSuffix(".swift") {
            var headerLines = 0

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: Date())

            var createdBy = "//  Created by \(configuration.configuredName) on \(date)."
            let file = element
            let path = URL(fileURLWithPath: file)
            guard let contents = try? String(contentsOf: path, encoding: .utf8) else {
                printC("Failed to read \(file)", color: CLIColors.red)
                continue
            }
            let filename = file.components(separatedBy: "/").last
            var lines = contents.components(separatedBy: .newlines)

            if lines.isEmpty {
                break
            }

            if lines[0].hasPrefix("#!") || file == "Package.swift" {
                continue
            }

            for line in lines {
                if line.hasPrefix("//") {
                    if line.contains("Created by") {
                        createdBy = line
                    }

                    headerLines += 1
                } else {
                    break
                }
            }

            lines.removeFirst(Int(headerLines))

            let headerTemplate = configurationValueContent(
                configuration.swiftFileHeader,
                fileNames: ["HEADER.swift", "Header.swift", "header.swift", ".swiftfile"]
            )
            let renderedHeader = headerTemplate.map {
                renderTemplate($0, configuration: configuration, filename: filename)
            }
            let header = renderedHeader?.components(separatedBy: .newlines) ?? [
                "//",
                "//  \(filename ?? "")",
                "//  \(productName)",
                "//",
                createdBy,
                "//  \(configuration.configuredWebsite)",
                "//",
                "//  https://github.com/\(configuration.configuredgithub)/\(productName)",
                "//  MIT License",
                "//"
            ]

            lines.insert(contentsOf: header, at: 0)
            let newContents = lines.joined(separator: "\n")
            do {
                try newContents.write(to: path, atomically: true, encoding: .utf8)
                printC("Updated header for \(file)", color: CLIColors.green)
            } catch {
                printC("Failed to update header for \(file)", color: CLIColors.red)
            }
        }
    }
}
