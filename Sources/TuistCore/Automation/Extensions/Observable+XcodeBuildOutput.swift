import Foundation
import RxSwift
import TuistSupport

public extension Observable where Element == SystemEvent<XcodeBuildOutput> {
    func printFormattedOutput() -> Observable<SystemEvent<XcodeBuildOutput>> {
        self.do(onNext: { event in
            switch event {
            case let .standardError(error):
                if let string = error.formatted, let data = string.data(using: .utf8) {
                    FileHandle.standardError.write(data)
                }
            case let .standardOutput(output):
                if let string = output.formatted, let data = string.data(using: .utf8) {
                    FileHandle.standardOutput.write(data)
                }
            }
        })
    }
}
