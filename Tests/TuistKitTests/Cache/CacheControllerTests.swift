import Basic
import Foundation
import TuistCacheTesting
import TuistCore
import TuistCoreTesting
import TuistLoader
import TuistLoaderTesting
import TuistSupport
import XCTest

@testable import TuistKit
@testable import TuistSupportTesting

final class CacheControllerTests: TuistUnitTestCase {
    var generator: MockProjectGenerator!
    var graphContentHasher: MockGraphContentHasher!
    var xcframeworkBuilder: MockXCFrameworkBuilder!
    var manifestLoader: MockManifestLoader!
    var cache: MockCacheStorage!
    var subject: CacheController!

    override func setUp() {
        generator = MockProjectGenerator()
        xcframeworkBuilder = MockXCFrameworkBuilder()
        cache = MockCacheStorage()
        manifestLoader = MockManifestLoader()
        graphContentHasher = MockGraphContentHasher()
        subject = CacheController(generator: generator,
                                  xcframeworkBuilder: xcframeworkBuilder,
                                  cache: cache,
                                  graphContentHasher: graphContentHasher)

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        generator = nil
        xcframeworkBuilder = nil
        graphContentHasher = nil
        manifestLoader = nil
        cache = nil
        subject = nil
    }

    func test_cache_builds_and_caches_the_frameworks() throws {
        // Given
        let path = try temporaryPath()
        let xcworkspacePath = path.appending(component: "Project.xcworkspace")
        let cache = GraphLoaderCache()
        let graph = Graph.test(cache: cache)
        let project = Project.test(path: path, name: "Cache")
        let aTarget = Target.test(name: "A")
        let bTarget = Target.test(name: "B")
        let axcframeworkPath = path.appending(component: "A.xcframework")
        let bxcframeworkPath = path.appending(component: "B.xcframework")
        try FileHandler.shared.createFolder(axcframeworkPath)
        try FileHandler.shared.createFolder(bxcframeworkPath)

        let nodeWithHashes = [
            TargetNode.test(project: project, target: aTarget): "A_HASH",
            TargetNode.test(project: project, target: bTarget): "B_HASH",
        ]

        manifestLoader.manifestsAtStub = { (loadPath: AbsolutePath) -> Set<Manifest> in
            XCTAssertEqual(loadPath, path)
            return Set(arrayLiteral: .project)
        }
        generator.generateWithGraphStub = { (loadPath, _) -> (AbsolutePath, Graphing) in
            XCTAssertEqual(loadPath, path)
            return (xcworkspacePath, graph)
        }
        graphContentHasher.contentHashesStub = nodeWithHashes

        xcframeworkBuilder.buildWorkspaceStub = { _xcworkspacePath, target in
            switch (_xcworkspacePath, target) {
            case (xcworkspacePath, aTarget): return .success(axcframeworkPath)
            case (xcworkspacePath, bTarget): return .success(bxcframeworkPath)
            default: return .failure(TestError("Received invalid Xcode project path or target"))
            }
        }

        try subject.cache(path: path)

        // Then
        XCTAssertPrinterOutputContains("""
        Hashing cacheable frameworks
        All cacheable frameworks have been cached successfully
        """)
        XCTAssertFalse(FileHandler.shared.exists(axcframeworkPath))
        XCTAssertFalse(FileHandler.shared.exists(bxcframeworkPath))
    }
}
