import Foundation

public enum Manifest: CaseIterable {
    case project
    case workspace
    case config
    case setup
    case galaxy

    /// This was introduced to rename a file name without breaking existing projects.
    public var deprecatedFileName: String? {
        switch self {
        case .config:
            return "TuistConfig.swift"
        default:
            return nil
        }
    }

    public var fileName: String {
        switch self {
        case .project:
            return "Project.swift"
        case .workspace:
            return "Workspace.swift"
        case .config:
            return "Config.swift"
        case .setup:
            return "Setup.swift"
        case .galaxy:
            return "Galaxy.swift"
        }
    }
}
