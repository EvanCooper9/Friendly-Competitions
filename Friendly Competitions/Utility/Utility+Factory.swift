import CombineSchedulers
import Factory
import Foundation

extension Container {
    var scheduler: Factory<AnySchedulerOf<RunLoop>> {
        self { AnySchedulerOf<RunLoop>.main }
    }
}
