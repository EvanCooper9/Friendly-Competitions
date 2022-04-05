import SwiftUI

extension View {
    func hud<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .top) {
            self
            if isPresented.wrappedValue {
                content()
                    .transition(.move(edge: .top).combined(with: .opacity).animation(.easeInOut))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isPresented.wrappedValue = false
                        }
                    }
                    .zIndex(1)
            }
        }
    }
}

extension View {
    func errorBanner(presenting error: Binding<Error?>) -> some View {
        hud(isPresented: .init(get: { error.wrappedValue != nil }, set: { _ in error.wrappedValue = nil })) {
            Text(error.wrappedValue?.localizedDescription ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(hex: "ff6161"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    
    private struct Container: View {
        
        private enum TestError: LocalizedError {
            case any
            
            var errorDescription: String? { localizedDescription }
            var localizedDescription: String { "Error: something happened!" }
        }
        
        @State private var showHUD = false
        @State private var error: Error?
        
        var body: some View {
            NavigationView {
                VStack {
                    Button("\(showHUD ? "Hide" : "Show") HUD") {
                        withAnimation {
                            showHUD.toggle()
                        }
                    }
                    
                    Button("\(error == nil ? "Show" : "Hide") error") {
                        withAnimation {
                            error = error == nil ? TestError.any : nil
                        }
                    }
                }
            }
            .hud(isPresented: $showHUD) {
                Text("Example HUD")
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 5)
            }
            .errorBanner(presenting: $error)
        }
    }
    
    static var previews: some View {
        Container()
    }
}
