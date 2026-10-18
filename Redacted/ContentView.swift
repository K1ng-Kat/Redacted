import SwiftUI

struct ContentView: View {
    @StateObject private var investigation = InvestigationStore()
    @State private var isInvestigating = false

    var body: some View {
        Group {
            if isInvestigating {
                InvestigationView(store: investigation) {
                    isInvestigating = false
                }
            } else {
                HomeView(store: investigation) {
                    investigation.start()
                    isInvestigating = true
                }
            }
        }
        .tint(Noir.accent)
    }
}

#Preview {
    ContentView()
}
