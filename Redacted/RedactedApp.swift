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
                ContentView()
            }
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
