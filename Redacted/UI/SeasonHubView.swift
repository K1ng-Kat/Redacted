import SwiftUI

/// Live season HQ. All progress values come from completed cases; there are
/// no fake pass purchases, unearned rewards or unreleased content in this UI.
struct SeasonHubView: View {
    @ObservedObject var director: SeasonDirector
    @ObservedObject var store: CampaignStore
    let back: () -> Void

    private var season: RedactedSeason { director.displayed }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                ScreenHeader(title: "SEASON HQ", subtitle: "LIVE OPERATIONS", back: back)
                hero
                progressPanel
                objectives
                upcomingPanel
                GameKicker(text: "SEASON PROGRESS IS SAVED ON THIS DEVICE", color: Art.faded)
                    .padding(.top, 4)
            }
            .frame(maxWidth: 580)
            .padding(.horizontal, 17)
            .padding(.top, 10)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .navigationBarHidden(true)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("CURRENT OPERATION", systemImage: "shield.lefthalf.filled")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(Art.cyan)
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Art.cyan.opacity(0.9))
                    .font(.system(size: 23, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(season.heading)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(Art.gold)
                Text(displayTitle)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                    .foregroundStyle(Art.paper)
                Text("Play cases and collect Intel to build your investigation record.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if director.hasPublishedSchedule {
                Rectangle().fill(Art.edge.opacity(0.32)).frame(height: 1)
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        GameKicker(text: "TIME REMAINING", color: Art.faded)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(countdown(until: season.endsAt, from: context.date))
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(Art.paper)
                        }
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 5) {
                        GameKicker(text: "ENDS · UTC", color: Art.faded)
                        Text(utcDate(season.endsAt))
                            .font(.system(size: 11, weight: .semibold))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Art.cyan)
                    }
                }
            } else {
                Label("SEASON 1 · INVESTIGATIONS OPEN", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Art.mint)
            }
        }
        .padding(21)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(
                    colors: [Art.blue, Art.blueDeep, Art.ink],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Art.cyan.opacity(0.45), lineWidth: 1.2)
                }
                .shadow(color: Art.ink.opacity(0.34), radius: 19, y: 10)
        }
        .accessibilityElement(children: .contain)
    }

    private var displayTitle: String { season.title }

    private var progressPanel: some View {
        GameCard(accent: Art.gold) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    GameKicker(text: "SEASON INTEL", color: Art.gold)
                    Spacer()
                    Text("\(director.activity.intelCollected) INTEL")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Art.ink)
                        Capsule()
                            .fill(LinearGradient(colors: [Art.goldDark, Art.gold],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * progressFraction)
                    }
                }
                .frame(height: 11)
                HStack {
                    Text("INTEL LEVEL \(director.activity.intelCollected / 100 + 1)")
                    Spacer()
                    Text("\(director.activity.intelCollected % 100)/100 TO NEXT")
                }
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(Art.faded)
            }
        }
    }

    private var progressFraction: CGFloat {
        CGFloat(director.activity.intelCollected % 100) / 100.0
    }

    private var objectives: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                GameKicker(text: "FIELD OBJECTIVES", color: Art.cyan)
                Spacer()
                Text("\(store.totalStars) LIFETIME STARS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Art.faded)
            }
            objective(icon: "checkmark.shield.fill", name: "PLAY 5 CASES",
                      subtitle: "Play investigations during this season",
                      current: director.activity.casesCompleted, target: 5)
            objective(icon: "star.circle.fill", name: "COLLECT 20 STARS",
                      subtitle: "Earn stars by completing investigations",
                      current: director.activity.starsEarned, target: 20)
            objective(icon: "tray.full.fill", name: "COLLECT 300 INTEL",
                      subtitle: "Every case adds to your intel record",
                      current: director.activity.intelCollected, target: 300)
        }
    }

    private func objective(icon: String, name: String, subtitle: String,
                           current: Int, target: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(current >= target ? Art.mint : Art.cyan)
                .frame(width: 40, height: 42)
                .background(Art.ink.opacity(0.36))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 5)
            Text("\(min(current, target))/\(target)")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(current >= target ? Art.mint : Art.gold)
                .monospacedDigit()
        }
        .padding(12)
        .background(Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(Art.edge.opacity(0.36), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var upcomingPanel: some View {
        GameCard(accent: Art.edge) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    GameKicker(text: "NEXT SEASON", color: Art.cyan)
                    Spacer()
                    Image(systemName: "lock.shield.fill").foregroundStyle(Art.faded)
                }
                Text(director.upcoming.heading)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text(director.hasPublishedSchedule
                     ? "Next season's case files remain classified until they are released."
                     : "The next season's theme and start date have not been announced.")
                    .font(.system(size: 12))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
                if director.hasPublishedSchedule {
                    Label(utcDate(director.upcoming.startsAt),
                          systemImage: "calendar.badge.clock")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Art.cyan)
                }
            }
        }
    }

    private func utcDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy · HH:mm 'UTC'"
        return formatter.string(from: date)
    }

    private func countdown(until end: Date, from now: Date) -> String {
        let remaining = max(0, Int(ceil(end.timeIntervalSince(now))))
        let days = remaining / 86_400
        let hours = (remaining % 86_400) / 3_600
        let minutes = (remaining % 3_600) / 60
        let seconds = remaining % 60
        return String(format: "%02dD  %02d:%02d:%02d", days, hours, minutes, seconds)
    }
}
