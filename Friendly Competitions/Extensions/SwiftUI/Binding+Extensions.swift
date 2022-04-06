import SwiftUI

func ??<T> (left: Binding<T?>, right: T) -> Binding<T> {
    Binding<T> {
        return left.wrappedValue ?? right
    } set: {
        left.wrappedValue = $0
    }
}

extension Binding {
    func unwrapped<T>() -> Binding<T>? where Value == T? {
        guard let value = wrappedValue else { return nil }
        return Binding<T>(
            get: { value },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Binding {
    func mapTo<Mapped>(_ value: Mapped) -> Binding<Mapped> {
        return Binding<Mapped>(
            get: { value },
            set: { _ in }
        )
    }
}

//extension Binding<Wrapped> where Value == Wrapped? {
//    var isNotNil: Binding<Bool> {
//        Binding<Bool> {
//            self.wrappedValue != nil
//        } set: { newValue in
//            wrappedValue = newValue
//        }
//    }
//}
