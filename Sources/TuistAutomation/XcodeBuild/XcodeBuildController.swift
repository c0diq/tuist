import Basic
import Foundation
import RxSwift
import TuistCore
import TuistSupport
import XcbeautifyLib

public final class XcodeBuildController: XcodeBuildControlling {
    // MARK: - Attributes

    /// Instance to format xcodebuild output.
    private let parser: Parsing

    public convenience init() {
        self.init(parser: Parser())
    }

    init(parser: Parsing) {
        self.parser = parser
    }

    public func build(_ target: XcodeBuildTarget,
                      scheme: String,
                      clean: Bool = false,
                      arguments: XcodeBuildArgument...) -> Observable<SystemEvent<XcodeBuildOutput>> {
        var command = ["/usr/bin/xcrun", "xcodebuild"]

        // Action
        if clean {
            command.append("clean")
        }
        command.append("build")

        // Scheme
        command.append(contentsOf: ["-scheme", scheme])

        // Target
        command.append(contentsOf: target.xcodebuildArguments)

        // Arguments
        command.append(contentsOf: arguments.flatMap { $0.arguments })

        return run(command: command)
    }

    public func archive(_ target: XcodeBuildTarget,
                        scheme: String,
                        clean: Bool,
                        archivePath: AbsolutePath,
                        arguments: XcodeBuildArgument...) -> Observable<SystemEvent<XcodeBuildOutput>> {
        var command = ["/usr/bin/xcrun", "xcodebuild"]

        // Action
        if clean {
            command.append("clean")
        }
        command.append("archive")

        // Scheme
        command.append(contentsOf: ["-scheme", scheme])

        // Target
        command.append(contentsOf: target.xcodebuildArguments)

        // Archive path
        command.append(contentsOf: ["-archivePath", archivePath.pathString])

        // Arguments
        command.append(contentsOf: arguments.flatMap { $0.arguments })

        return run(command: command)
    }

    public func createXCFramework(frameworks: [AbsolutePath], output: AbsolutePath) -> Observable<SystemEvent<XcodeBuildOutput>> {
        var command = ["/usr/bin/xcrun", "xcodebuild", "-create-xcframework"]
        command.append(contentsOf: frameworks.flatMap { ["-framework", $0.pathString] })
        command.append(contentsOf: ["-output", output.pathString])
        return run(command: command)
    }

    fileprivate func run(command: [String]) -> Observable<SystemEvent<XcodeBuildOutput>> {
        let colored = Environment.shared.shouldOutputBeColoured
        return System.shared.observable(command, verbose: false)
            .compactMap { event -> SystemEvent<XcodeBuildOutput>? in
                switch event {
                case let .standardError(errorData):
                    guard let line = String(data: errorData, encoding: .utf8) else { return nil }
                    let formatedOutput = self.parser.parse(line: line, colored: colored)
                    return .standardError(XcodeBuildOutput(raw: line, formatted: formatedOutput))
                case let .standardOutput(outputData):
                    guard let line = String(data: outputData, encoding: .utf8) else { return nil }
                    let formatedOutput = self.parser.parse(line: line, colored: colored)
                    return .standardOutput(XcodeBuildOutput(raw: line, formatted: formatedOutput))
                }
            }
    }
}
