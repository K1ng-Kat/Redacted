import SwiftUI

/// Single entry point: one home screen and one guided case.
/// The legacy multi-tab investigation remains out of the player journey.
struct ContentView: View {
    @StateObject private var store = InvestigationStore()
    @State private var playing = false

    var body: some View {
        Group {
            if playing {
                CaseAdventureView(store: store) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        playing = false
                    }
                }
            } else {
                GameHomeView(store: store) {
                    store.start()
                    withAnimation(.easeInOut(duration: 0.22)) {
                        playing = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
