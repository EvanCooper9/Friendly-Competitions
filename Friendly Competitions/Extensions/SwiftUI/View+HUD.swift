import SwiftUI

enum HUDState: Equatable {
    case error(Error)
    case success(text: String)
    case neutral(text: String)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error):
            return true
        case (.success, .success):
            return true
        case (.neutral, .neutral):
            return true
        default:
            return false
        }
    }
}

struct HUD: View {
    
    let state: HUDState
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(foregroundColor)
            .padding()
            .background(backgroundColor)
            .cornerRadius(5)
            .padding()
            .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 5)
            .cornerRadius(10)
    }
    
    @ViewBuilder
    private var backgroundColor: some View {
        switch state {
        case .error:
            Color.red
        case .success:
            Color.green
        case .neutral:
            Color.white
        }
    }
    
    private var foregroundColor: Color {
        switch state {
        case .error:
            return .white
        case .success:
            return .white
        case .neutral:
            return .black
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch state {
        case .error(let error):
            Text(error.localizedDescription)
        case .success(let text):
            Text(text)
        case .neutral(let text):
            Text(text)
        }
    }
}

struct HUDContainer<MainContent: View>: View {
    
    let mainContent: MainContent
    @Binding var hudState: HUDState?
    
    @State private var dismissTask: Task<Void, Error>? {
        willSet { dismissTask?.cancel() }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            mainContent
            if let state = hudState {
                HUD(state: state)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                    .onChange(of: state) { _ in
                        dismissAfterDelay()
                    }
                    .onAppear(perform: dismissAfterDelay)
                    .zIndex(1)
            }
        }
    }
    
    private func dismissAfterDelay() {
        dismissTask = Task(priority: .userInitiated) {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()
            DispatchQueue.main.async {
                withAnimation {
                    hudState = nil
                }
            }
        }
    }
}

extension View {
    func hud(state: Binding<HUDState?>) -> some View {
        HUDContainer(mainContent: self, hudState: state)
    }
}

struct HUD_Previews: PreviewProvider {
    
    private struct Container: View {
        
        enum TestError: LocalizedError {
            case any
            var errorDescription: String? { "Bad error!" }
        }
        
        @State private var hudState: HUDState?
        
        var body: some View {
            VStack(spacing: 30) {
                Spacer()
                Button("Error HUD") {
                    hudState = .error(TestError.any)
                }
                Button("Success HUD") {
                    hudState = .success(text: "Something good!")
                }
                Button("Neutral HUD") {
                    hudState = .neutral(text: "Neutral info")
                }
                Spacer()
            }
            .hud(state: $hudState)
        }
    }
    
    static var previews: some View {
        Container()
    }
}
