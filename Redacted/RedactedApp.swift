import SwiftUI
import UIKit

@main
struct RedactedApp: App {
    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone &&
               !ProcessInfo.processInfo.isOperatingSystemAtLeast(
                   OperatingSystemVersion(majorVersion: 18, minorVersion: 0, patchVersion: 0)) {
                PhoneOSRequirementView()
            } else {
                RedactedFirstFrameGate()
            }
        }
    }
}

/// A lightweight first UIKit frame before constructing the game.
/// The app's old heavy state initialization could keep the static iOS
/// LaunchScreen visible without an activity indicator on cold starts.
private struct RedactedFirstFrameGate: View {
    @State private var gameReadyToMount = false

    var body: some View {
        Group {
            if gameReadyToMount {
                ContentView()
            } else {
                ZStack {
                    Color(red: 0.035, green: 0.055, blue: 0.12)
                        .ignoresSafeArea()
                    VStack(spacing: 13) {
                        Text("REDACTED")
                            .font(.system(size: 33, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 1, green: 0.98, blue: 0.89))
                        Text("DETECTIVE AGENCY")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.37, green: 0.89, blue: 0.97))
                        ProgressView()
                            .tint(Color(red: 0.37, green: 0.89, blue: 0.97))
                            .padding(.top, 8)
                            .accessibilityLabel("Opening Redacted")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard !gameReadyToMount else { return }
            // Allow at least a few UIKit display cycles for this first frame.
            // This is a presentation gate, not artificial game initialization.
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            gameReadyToMount = true
        }
    }
}

/// A universal iOS app must have one common technical deployment target.
/// iPadOS 17 supports iPad 6; phones below iOS 18 see this informative guard.
/// This is not an App Store-level installation restriction.
private struct PhoneOSRequirementView: View {
    var body: some View {
        ZStack {
            GameBackdrop()
            VStack(spacing: 19) {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Art.gold)
                GameTitle(text: "UPDATE REQUIRED", size: 29)
                Text("REDACTED needs iOS 18 or later on iPhone. Please update your iPhone in Settings to keep investigating.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Art.paper)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("iPad models can play on iPadOS 17 or later.")
                    .font(.system(size: 13))
                    .foregroundStyle(Art.faded)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: 460)
        }
    }
}
