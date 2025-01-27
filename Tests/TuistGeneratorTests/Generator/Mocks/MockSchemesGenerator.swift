import Basic
import Foundation
import TuistCore
import TuistCoreTesting
@testable import TuistGenerator

final class MockSchemesGenerator: SchemesGenerating {
    func generateProjectSchemes(project _: Project, generatedProject _: GeneratedProject, graph _: Graphing) throws -> [SchemeDescriptor] {
        []
    }

    func generateWorkspaceSchemes(workspace _: Workspace, generatedProjects _: [AbsolutePath: GeneratedProject], graph _: Graphing) throws -> [SchemeDescriptor] {
        []
    }
}
