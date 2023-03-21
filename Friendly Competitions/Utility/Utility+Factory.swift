import CombineSchedulers
import Factory
import Foundation

extension Container {
    var scheduler: Factory<AnySchedulerOf<RunLoop>> {
        Factory(self) { AnySchedulerOf<RunLoop>.main }
    }
    
    var usersCache: Factory<UsersCache> {
        Factory(self) { UsersStore() }.scope(.shared)
    }
}
