import Firebase
import FirebaseFirestore

final class ListenerBag {
    
    private var registrations = [ListenerRegistration]()
    
    deinit {
        registrations.forEach {
            $0.remove()
        }
    }
    
    func store(_ listener: ListenerRegistration) {
        registrations.append(listener)
    }
}

extension ListenerRegistration {
    func store(in bag: ListenerBag) {
        bag.store(self)
    }
}
