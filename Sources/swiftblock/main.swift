import ArgumentParser
import Foundation
import SwiftBlockCore

@main
struct SwiftBlock: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftblock",
        abstract: "Swift project generator CLI",
        subcommands: [Init.self]
    )
}

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new SwiftUI project using Tuist, SwiftLint, and SwiftFormat"
    )

    @Argument(help: "Project name")
    var projectName: String

    @Option(name: [.customShort("b"), .long], help: "Bundle identifier prefix (default: io.ardyan)")
    var bundlePrefix: String = "io.ardyan"

    @Option(name: [.customShort("t"), .long], help: "Custom template path")
    var templatePath: String = "/usr/local/share/swiftblock/Templates/BaseProject-SwiftUI"

    func run() throws {
        print("🛠️ Generating project: \(projectName)")

        let options = ProjectGeneratorOptions(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            templatePath: templatePath
        )

        let generator = ProjectGenerator()

        do {
            try generator.generateProject(options: options)
            print("✅ Project created at \(options.outputPath)")
            print("🔁 Placeholders replaced with \(projectName) (bundle prefix: \(bundlePrefix))")
        } catch {
            print("❌ \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}
