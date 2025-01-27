import Basic
import Foundation
import ProjectDescription
import TuistCore
import TuistSupport

enum ConfigManifestMapperError: FatalError {
    /// Thrown when the cloud URL is invalid.
    case invalidCloudURL(String)

    /// Error type.
    var type: ErrorType {
        switch self {
        case .invalidCloudURL: return .abort
        }
    }

    /// Error description.
    var description: String {
        switch self {
        case let .invalidCloudURL(url):
            return "The cloud URL '\(url)' is not a valid URL"
        }
    }
}

extension TuistCore.Config {
    /// Maps a ProjectDescription.Config instance into a TuistCore.Config model.
    /// - Parameters:
    ///   - manifest: Manifest representation of Tuist config.
    ///   - generatorPaths: Generator paths.
    static func from(manifest: ProjectDescription.Config) throws -> TuistCore.Config {
        let generationOptions = try manifest.generationOptions.map { try TuistCore.Config.GenerationOption.from(manifest: $0) }
        let compatibleXcodeVersions = TuistCore.CompatibleXcodeVersions.from(manifest: manifest.compatibleXcodeVersions)
        var cloudURL: URL?
        if let manifestCloudURL = manifest.cloudURL {
            if let manifestCloudURL = URL(string: manifestCloudURL) {
                cloudURL = manifestCloudURL
            } else {
                throw ConfigManifestMapperError.invalidCloudURL(manifestCloudURL)
            }
        }
        return TuistCore.Config(compatibleXcodeVersions: compatibleXcodeVersions, cloudURL: cloudURL, generationOptions: generationOptions)
    }
}

extension TuistCore.Config.GenerationOption {
    /// Maps a ProjectDescription.Config.GenerationOptions instance into a TuistCore.Config.GenerationOptions model.
    /// - Parameters:
    ///   - manifest: Manifest representation of Tuist config generation options
    ///   - generatorPaths: Generator paths.
    static func from(manifest: ProjectDescription.Config.GenerationOptions) throws -> TuistCore.Config.GenerationOption {
        switch manifest {
        case let .xcodeProjectName(templateString):
            return .xcodeProjectName(templateString.description)
        }
    }
}
