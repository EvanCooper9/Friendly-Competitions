import SwiftUI

extension View {
    func errorBanner(presenting error: Binding<Error?>) -> some View {
        ZStack(alignment: .top) {
            self
            if let errorValue = error.wrappedValue {
                Text(errorValue.localizedDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(hex: "ff6161"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).animation(.spring()))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [error] in
                            error.wrappedValue = nil
                        }
                    }
            }
        }
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    
    enum TestError: LocalizedError {
        case any
        
        var errorDescription: String? { localizedDescription }
        var localizedDescription: String { "Error: something happened!" }
    }
    
    static var previews: some View {
        Text("Hello, world!")
            .frame(maxHeight: .infinity)
            .errorBanner(presenting: .constant(TestError.any))
    }
}
