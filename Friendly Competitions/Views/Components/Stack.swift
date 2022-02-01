import SwiftUI

struct Stack<Content: View>: View {

    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            stackItem
                .padding(.top, 10)
                .padding(.horizontal, 10)
            stackItem
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal, 5)
            ZStack {
                backgroundColor
                content
            }
            .cornerRadius(8)
            .shadow(color: shadowColor, radius: 10, x: 0, y: 0)
            .padding(.bottom, 20)
        }
    }

    private var stackItem: some View {
        backgroundColor
            .cornerRadius(8)
            .shadow(color:shadowColor, radius: 10, x: 0, y: 0)
    }

    private var backgroundColor: some View {
        colorScheme == .light ? Color.white : Color(red: 10/255, green: 10/255, blue: 10/255)
    }

    private var shadowColor: Color {
        colorScheme == .light ? .black.opacity(0.05) : .white.opacity(0.05)
    }
}

struct Stack_Previews: PreviewProvider {
    static var previews: some View {
        Stack {
            Text("Top stack guy")
        }
        .frame(width: 200, height: 200)
    }
}
