import Basic
import Foundation
import TuistCore
import TuistGenerator
import TuistLoader

protocol ProjectGenerating {
    @discardableResult
    func generate(path: AbsolutePath, projectOnly: Bool) throws -> AbsolutePath
    func generateWithGraph(path: AbsolutePath, projectOnly: Bool) throws -> (AbsolutePath, Graphing)
}

class ProjectGenerator: ProjectGenerating {
    private let manifestLoader: ManifestLoading = ManifestLoader()
    private let manifestLinter: ManifestLinting = ManifestLinter()
    private let graphLinter: GraphLinting = GraphLinter()
    private let environmentLinter: EnvironmentLinting = EnvironmentLinter()
    private let generator: DescriptorGenerating = DescriptorGenerator()
    private let writer: XcodeProjWriting = XcodeProjWriter()
    private let cocoapodsInteractor: CocoaPodsInteracting = CocoaPodsInteractor()
    private let swiftPackageManagerInteractor: SwiftPackageManagerInteracting = SwiftPackageManagerInteractor()
    private let modelLoader: GeneratorModelLoading
    private let graphLoader: GraphLoading

    init() {
        modelLoader = GeneratorModelLoader(manifestLoader: manifestLoader,
                                           manifestLinter: manifestLinter)
        graphLoader = GraphLoader(modelLoader: modelLoader)
    }

    func generate(path: AbsolutePath, projectOnly: Bool) throws -> AbsolutePath {
        let (generatedPath, _) = try generateWithGraph(path: path, projectOnly: projectOnly)
        return generatedPath
    }

    func generateWithGraph(path: AbsolutePath, projectOnly: Bool) throws -> (AbsolutePath, Graphing) {
        let manifests = manifestLoader.manifests(at: path)

        if projectOnly {
            return try generateProject(path: path)
        } else if manifests.contains(.workspace) {
            return try generateWorkspace(path: path)
        } else if manifests.contains(.project) {
            return try generateProjectWorkspace(path: path)
        } else {
            throw ManifestLoaderError.manifestNotFound(path)
        }
    }

    private func generateProject(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (graph, project) = try graphLoader.loadProject(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let projectDescriptor = try generator.generateProject(project: project, graph: graph)

        // Write
        try writer.write(project: projectDescriptor)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: projectDescriptor.xcodeprojPath.basename)

        return (projectDescriptor.xcodeprojPath, graph)
    }

    private func generateWorkspace(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (graph, workspace) = try graphLoader.loadWorkspace(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let updatedWorkspace = workspace.merging(projects: graph.projectPaths)
        let workspaceDescriptor = try generator.generateWorkspace(workspace: updatedWorkspace,
                                                                  graph: graph)

        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: workspaceDescriptor.xcworkspacePath.basename)

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    private func generateProjectWorkspace(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (graph, project) = try graphLoader.loadProject(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let workspace = Workspace(path: path, name: project.name, projects: graph.projectPaths)
        let workspaceDescriptor = try generator.generateWorkspace(workspace: workspace, graph: graph)

        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: workspaceDescriptor.xcworkspacePath.basename)

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    private func lint(graph: Graphing) throws {
        let config = try graphLoader.loadConfig(path: graph.entryPath)

        try environmentLinter.lint(config: config).printAndThrowIfNeeded()
        try graphLinter.lint(graph: graph).printAndThrowIfNeeded()
    }

    private func postGenerationActions(for graph: Graph, workspaceName: String) throws {
        try swiftPackageManagerInteractor.install(graph: graph, workspaceName: workspaceName)
        try cocoapodsInteractor.install(graph: graph)
    }
}
