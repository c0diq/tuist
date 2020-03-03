import Foundation
import TuistCore
import TuistSupport
import RxSwift
import Basic

public protocol CacheGraphMapping {
    func map(graph: Graphing) -> Single<Graphing>
}

public class CacheGraphMapper: CacheGraphMapping {
    
    // MARK: - Attributes
    
    /// Cache.
    private let cache: CacheStoraging
    
    /// Graph content hasher.
    private let graphContentHasher: GraphContentHashing
    
    /// Dispatch queue.
    private let queue: DispatchQueue
    
    // MARK: - Init
    
    public convenience init() {
        self.init(cache: Cache(),
                  graphContentHasher: GraphContentHasher())
    }
    
    private init(cache: CacheStoraging,
                 graphContentHasher: GraphContentHashing,
                 queue: DispatchQueue = CacheGraphMapper.dispatchQueue()) {
        self.cache = cache
        self.graphContentHasher = graphContentHasher
        self.queue = queue
    }
    
    // MARK: - CacheGraphMapping
    
    public func map(graph: Graphing) -> Single<Graphing> {
        return self.hashes(graph: graph).flatMap({ self.map(graph: graph, hashes: $0) })
    }
    
    // MARK: - Fileprivate
    
    fileprivate static func dispatchQueue() -> DispatchQueue {
        let qos: DispatchQoS = .userInitiated
        return DispatchQueue(label: "io.tuist.cache-graph-mapper.\(qos)", qos: qos, attributes: [], target: nil)
    }
    
    fileprivate func hashes(graph: Graphing) -> Single<[TargetNode: String]> {
        return Single.create { (observer) -> Disposable in
            do {
                let hashes = try self.graphContentHasher.contentHashes(for: graph)
                observer(.success(hashes))
            } catch {
                observer(.error(error))
            }
            return Disposables.create {}
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(queue: self.queue))
    }
    
    fileprivate func map(graph: Graphing, hashes: [TargetNode: String]) -> Single<Graphing> {
        
        
    }
    
    fileprivate func fetch(hashes: [TargetNode: String]) -> Single<[TargetNode: AbsolutePath]> {
        let singles = hashes.map({ target -> Single<(TargetNode, AbsolutePath)> in
            let hash = target.value
            return self.cache.fetch(hash: hash).map({ (target.key, $0) })
        })
        return Single.zip(singles).map({
            $0.reduce(into: [TargetNode: AbsolutePath](), { $0[$1.0] = $1.1 })
        })
        
    }

}
