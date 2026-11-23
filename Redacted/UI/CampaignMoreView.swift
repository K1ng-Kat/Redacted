import SwiftUI

/// All of the original settings and secondary features remain available.
/// This is a permanent, navigable tab; online setup never hides these items.
struct CampaignMoreView: View {
    let settings: () -> Void
    let guide: () -> Void
    let stats: () -> Void
    let wardrobe: () -> Void
    let season: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        GameTitle(text: "MORE", size: 30)
                        GameKicker(text: "YOUR DETECTIVE HQ", color: Art.cyan)
                    }
                    Spacer()
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Art.cyan)
                        .accessibilityHidden(true)
                }
                .padding(.top, 10)

                Button {
                    GameEffects.shared.tap()
                    settings()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(Art.ink)
                            .frame(width: 50, height: 50)
                            .background(Art.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("SETTINGS")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Text("Audio, haptics, difficulty, hints, saves & credits")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Art.faded)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 3)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Art.cyan)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Art.cyan.opacity(0.68), lineWidth: 1))
                }
                .buttonStyle(PressGameStyle())
                .accessibilityHint("Open every game preference and save option")

                GameKicker(text: "EXPLORE REDACTED", color: Art.gold)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                   GridItem(.flexible(), spacing: 11)],
                          spacing: 11) {
                    feature(symbol: "person.crop.square.fill",
                            title: "STYLE LAB",
                            subtitle: "Outfits, cosmetics & shop",
                            accent: Art.gold, action: wardrobe)
                    feature(symbol: "rosette",
                            title: "PROFILE",
                            subtitle: "Rank, XP & detective stats",
                            accent: Art.mint, action: stats)
                    feature(symbol: "book.closed.fill",
                            title: "HOW TO PLAY",
                            subtitle: "Game rules & case guidance",
                            accent: Art.cyan, action: guide)
                    feature(symbol: "calendar.badge.clock",
                            title: "SEASON HQ",
                            subtitle: "Chapters, seasons & Intel",
                            accent: Art.coral, action: season)
                }

                GameCard(accent: Art.edge) {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: DetectiveSocialConfiguration.isConfigured
                              ? "network" : "wifi.slash")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Art.cyan)
                        VStack(alignment: .leading, spacing: 5) {
                            GameKicker(text: "DETECTIVE NETWORK", color: Art.cyan)
                            Text(DetectiveSocialConfiguration.isConfigured
                                 ? "Use the Duels and Social tabs for private matches, friends and Task Forces."
                                 : "Duels and Social are visible in their tabs. Online matches and accounts require the service to be enabled.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Art.faded)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: 580)
            .padding(.horizontal, 17)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
    }

    private func feature(symbol: String, title: String, subtitle: String,
                         accent: Color, action: @escaping () -> Void) -> some View {
        Button {
            GameEffects.shared.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(height: 35, alignment: .topLeading)
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
            .background(Art.blueDeep)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Art.edge.opacity(0.4), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PressGameStyle())
    }
}
