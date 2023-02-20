import CombineSchedulers
import Factory
import Foundation

extension Container {
    static let scheduler = Factory(scope: .shared) { AnySchedulerOf<RunLoop>.main }
}
