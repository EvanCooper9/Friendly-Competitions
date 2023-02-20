import SwiftUI

func ??<T> (left: Binding<T?>, right: T) -> Binding<T> {
    Binding<T> {
        return left.wrappedValue ?? right
    } set: {
        left.wrappedValue = $0
    }
}
