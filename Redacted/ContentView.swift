import SwiftUI

struct ContentView: View {
    @StateObject private var store = CampaignStore()
    @State private var route: Route = .home
    @State private var navigationHistory: [Route] = []
    @State private var activeLevel = 1
    @State private var pendingInvite: String?
    @State private var startupComplete = false
    @AppStorage("redacted.setup.complete") private var setupComplete = false
    @AppStorage("redacted.age.mode") private var ageModeRaw = DetectiveAgeMode.investigator.rawValue
    @State private var backDrag: CGFloat = 0
    @State private var backCompleting = false
    @State private var startupProgress = 0.04
    @State private var startupStep = "CONNECTING TO THE ARCHIVE"
    @AppStorage("redacted.tutorial.home") private var homeCoached = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("redacted.music.enabled") private var musicEnabled = true
    @AppStorage("redacted.music.menu.volume") private var menuVolume = 0.55
    @AppStorage("redacted.music.level.volume") private var levelVolume = 0.12

    private enum Route: Equatable {
        case home, levels, play, settings, guide, stats, wardrobe, multiplayer, friends
    }

    var body: some View {
        ZStack {
            GameBackdrop()
            if startupComplete {
                if setupComplete {
                    swipeNavigation
                        .transition(.opacity)
                } else {
                    AgeOnboardingView { mode in
                        // Only the chosen difficulty is persisted. The exact
                        // numeric age never leaves the transient setup view.
                        ageModeRaw = mode.rawValue
                        setupComplete = true
                        GameEffects.shared.success()
                        openPendingInvite()
                    }
                    .transition(.opacity)
                }
            } else {
                StartupLoadingView(progress: startupProgress, stage: startupStep)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .overlay {
            if startupComplete && setupComplete && route == .home &&
               !homeCoached && store.levelsCompleted == 0 {
                GameCoachOverlay(
                    title: "YOUR FIRST CASE!",
                    detail: "Tap PLAY to investigate. Solve cases to earn coins, stars, and new detective identities.",
                    button: "PLAY FIRST CASE",
                    symbol: "hand.point.up.left.fill",
                    portraitTheme: nil
                ) {
                    homeCoached = true
                    launch(store.nextLevel)
                }
            }
        }
        .task {
            await prepareStartup()
            CloudSaveManager.shared.attach(store)
            MultiplayerService.shared.attach(store)
            openPendingInvite()
        }
        .onOpenURL { url in
            guard url.scheme == "redacted-detective",
                  url.host == "join",
                  let code = url.pathComponents.last,
                  code.count == 6 else { return }
            pendingInvite = code
            openPendingInvite()
        }
        .onChange(of: route) { _, _ in syncMusic() }
        .onChange(of: startupComplete) { _, _ in
            syncMusic()
            openPendingInvite()
        }
        .onChange(of: setupComplete) { _, _ in openPendingInvite() }
        .onChange(of: musicEnabled) { _, _ in syncMusic() }
        .onChange(of: menuVolume) { _, _ in syncMusic() }
        .onChange(of: levelVolume) { _, _ in syncMusic() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncMusic()
                MultiplayerService.shared.startPresence()
            } else {
                GameMusicController.shared.pause()
                MultiplayerService.shared.stopPresence()
            }
        }
    }

    @ViewBuilder
    private var swipeNavigation: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                if backDrag > 0, let previous = navigationHistory.last {
                    screen(for: previous)
                        .offset(x: -min(34, max(0, proxy.size.width - backDrag) * 0.06))
                        .allowsHitTesting(false)
                }

                mainGame
                    .offset(x: backDrag)
                    .shadow(color: Art.ink.opacity(backDrag > 0 ? 0.56 : 0),
                            radius: backDrag > 0 ? 14 : 0, x: -6)
                    .allowsHitTesting(!backCompleting)
            }
            .clipped()
            .overlay(alignment: .leading) {
                // Only this narrow bezel strip receives the gesture. Nothing
                // competes with scrolling, keypad buttons, or radio sliders.
                if !navigationHistory.isEmpty && !backCompleting {
                    Color.clear
                        .frame(width: 22)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 9)
                                .onChanged { value in
                                    guard value.translation.width > 0,
                                          abs(value.translation.height) <
                                            max(45, abs(value.translation.width) * 0.7)
                                    else { return }
                                    backDrag = min(proxy.size.width,
                                                   max(0, value.translation.width))
                                }
                                .onEnded { value in
                                    let completionThreshold = min(112, proxy.size.width * 0.32)
                                    let projected = value.predictedEndTranslation.width
                                    if backDrag > completionThreshold ||
                                       projected > completionThreshold * 1.7 {
                                        completeEdgeBack(width: proxy.size.width)
                                    } else {
                                        withAnimation(.interactiveSpring(
                                            response: 0.24, dampingFraction: 0.88)) {
                                            backDrag = 0
                                        }
                                    }
                                }
                        )
                        .accessibilityHidden(true)
                }
            }
            .onChange(of: route) { _, _ in
                if !backCompleting { backDrag = 0 }
            }
        }
    }

    private func completeEdgeBack(width: CGFloat) {
        guard !backCompleting else { return }
        backCompleting = true
        let oldRoute = route
        withAnimation(.easeOut(duration: 0.17)) {
            backDrag = width
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(175))
            if route == oldRoute {
                // The actual previous screen was already visible while dragging.
                popScreen(animated: false)
            }
            backDrag = 0
            backCompleting = false
        }
    }

    @ViewBuilder
    private var mainGame: some View {
        screen(for: route)
    }

    @ViewBuilder
    private func screen(for destination: Route) -> some View {
        switch destination {
        case .home:
            CampaignHomeView(
                store: store,
                play: {
                    if store.stars(for: store.nextLevel) > 0 {
                        show(.levels)
                    } else {
                        launch(store.nextLevel)
                    }
                },
                levels: { show(.levels) },
                settings: { show(.settings) },
                guide: { show(.guide) },
                stats: { show(.stats) },
                wardrobe: { show(.wardrobe) },
                multiplayer: { show(.multiplayer) },
                friends: { show(.friends) }
            )
        case .levels:
            LevelSelectView(store: store, launch: launch, back: { popScreen() })
        case .play:
            if let mission = CampaignCatalog.mission(activeLevel) {
                MissionPlayView(
                    store: store,
                    mission: mission,
                    back: { popScreen() },
                    next: {
                        if activeLevel < 100 {
                            launch(activeLevel + 1)
                        } else {
                            popScreen()
                        }
                    }
                )
                .id(activeLevel)
            }
        case .settings:
            CampaignSettingsView(store: store, back: { popScreen() })
        case .guide:
            CampaignGuideView(back: { popScreen() }, begin: { launch(store.nextLevel) })
        case .stats:
            CampaignStatsView(store: store, back: { popScreen() },
                              customize: { show(.wardrobe) })
        case .wardrobe:
            DetectiveWardrobeView(store: store, back: { popScreen() })
        case .multiplayer:
            MultiplayerLobbyView(store: store, back: { popScreen() })
        case .friends:
            FriendsView(store: store, back: { popScreen() })
        }
    }

    @MainActor
    private func prepareStartup() async {
        guard !startupComplete else { return }
        // Show the authored loading UI before the first preparation update.
        // Prevents the screen being swapped before its first rendered frame.
        try? await Task.sleep(for: .milliseconds(160))
        guard !Task.isCancelled else { return }

        startupStep = "VERIFYING CASE FILES"
        // The campaign catalog and current save are loaded before gameplay.
        _ = CampaignCatalog.levels.count
        _ = store.nextLevel
        withAnimation(.linear(duration: 1.05)) {
            startupProgress = 0.48
        }
        try? await Task.sleep(for: .milliseconds(1050))

        startupStep = "PREPARING AUDIO"
        GameMusicController.shared.prepare()
        _ = GameEffects.shared // Preload button and coin sounds.
        withAnimation(.linear(duration: 1.05)) {
            startupProgress = 0.82
        }
        try? await Task.sleep(for: .milliseconds(1050))

        startupStep = "WELCOME, DETECTIVE"
        withAnimation(.linear(duration: 1.05)) {
            startupProgress = 1
        }
        // Let the same animatable fraction reach 100% before the fade.
        try? await Task.sleep(for: .milliseconds(1190))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            startupComplete = true
        }
    }

    private func syncMusic() {
        guard startupComplete && scenePhase == .active else { return }
        GameMusicController.shared.update(
            scene: route == .play || route == .multiplayer ? .level : .menu,
            enabled: musicEnabled,
            menuVolume: menuVolume,
            levelVolume: levelVolume
        )
    }

    private func setRoute(_ next: Route, animated: Bool = true) {
        guard next != route else { return }
        if startupComplete && scenePhase == .active {
            GameMusicController.shared.update(
                scene: next == .play || next == .multiplayer ? .level : .menu,
                enabled: musicEnabled,
                menuVolume: menuVolume,
                levelVolume: levelVolume
            )
        }
        if animated {
            withAnimation(.easeOut(duration: 0.14)) { route = next }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { route = next }
        }
    }

    private func show(_ next: Route) {
        guard next != route else { return }
        navigationHistory.append(route)
        setRoute(next)
    }

    private func popScreen(animated: Bool = true) {
        guard let previous = navigationHistory.popLast() else { return }
        setRoute(previous, animated: animated)
    }

    private func openPendingInvite() {
        guard startupComplete, setupComplete, let code = pendingInvite else { return }
        pendingInvite = nil
        if route != .multiplayer { show(.multiplayer) }
        MultiplayerService.shared.attach(store)
        Task { await MultiplayerService.shared.joinRoom(code) }
    }

    private func launch(_ level: Int) {
        guard store.isUnlocked(level) else { return }
        store.recordStarted(level)
        activeLevel = level
        // "Next level" replaces the current gameplay screen, keeping
        // the last real menu as the back destination.
        if route != .play {
            navigationHistory.append(route)
        }
        setRoute(.play)
    }

}

struct CampaignHomeView: View {
    @ObservedObject var store: CampaignStore
    let play: () -> Void
    let levels: () -> Void
    let settings: () -> Void
    let guide: () -> Void
    let stats: () -> Void
    let wardrobe: () -> Void
    let multiplayer: () -> Void
    let friends: () -> Void

    private var episode: CampaignEpisode {
        CampaignCatalog.episodes[(store.nextLevel - 1) / 10]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                topBar
                identity
                featuredMission
                actions
                progress
                footer
            }
            .frame(maxWidth: 580)
            .padding(.horizontal, 17)
            .padding(.top, 9)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity)
            .background {
                HomeScrollBounceLock().frame(width: 0, height: 0)
            }
        }
        .background(GameBackdrop())
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Art.coral)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-5))
                Image(systemName: "eye.fill")
                    .font(.system(size: 23, weight: .black))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("REDACTED")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Text("DETECTIVE AGENCY")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(0.2)
                    .foregroundStyle(Art.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .layoutPriority(1)

            Spacer(minLength: 2)

            HStack(spacing: 6) {
                smallTopButton("questionmark.circle.fill", name: "How to play", action: guide)
                smallTopButton("gearshape.fill", name: "Settings", action: settings)
                smallTopButton("person.crop.circle.fill", name: "Detective profile", action: stats)
            }
        }
        .frame(minHeight: 45)
    }

    private func smallTopButton(_ symbol: String, name: String, action: @escaping () -> Void) -> some View {
        Button {
            GameEffects.shared.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Art.paper)
                .frame(width: 41, height: 44)
                .background(Art.blueDeep)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Art.edge.opacity(0.65), lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressGameStyle())
        .accessibilityLabel(name)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                StatChip(icon: "star.fill", value: "\(store.totalStars)", label: "STARS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                StatChip(icon: "checkmark.seal.fill", value: "\(store.levelsCompleted)/100",
                         label: "SOLVED", tint: Art.mint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            GameCard(accent: Art.gold) {
                VStack(spacing: 11) {
                    HStack(spacing: 12) {
                        DetectiveCharacter(store: store, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DETECTIVE LEVEL \(store.accountLevel)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            GameKicker(text: store.rankTitle, color: Art.cyan)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 5) {
                                CoinIcon(size: 19)
                                Text("\(store.coins)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                            }
                            HStack(spacing: 5) {
                                CrystalIcon(size: 20)
                                Text("\(store.crystals)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                            }
                        }
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Art.ink)
                            Capsule().fill(Art.gold)
                                .frame(width: proxy.size.width * store.rankProgress)
                        }
                    }
                    .frame(height: 9)
                    HStack {
                        GameKicker(text: store.xpForNextRank, color: Art.faded)
                        Spacer()
                        GameKicker(text: "TAP RANK FOR REWARDS", color: Art.gold)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        GameEffects.shared.tap()
                        stats()
                    }
                }
            }
            GameKicker(text: "WELCOME BACK, DETECTIVE", color: Art.gold)
            GameTitle(text: store.allCompleted ? "MASTER DETECTIVE!" : "CRACK THE\nNEXT CASE.", size: 32)
            Text("100 mysteries. 10 districts. Every clue counts.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Art.faded)
        }
    }

    private var featuredMission: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                DistrictIllustration(episode: episode.id)
                LinearGradient(colors: [.clear, Art.ink.opacity(0.12), Art.ink.opacity(0.92)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("LEVEL \(store.nextLevel)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(Art.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Art.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                        GameKicker(text: episode.title, color: Art.cyan)
                    }
                    Spacer()
                    if let level = CampaignCatalog.mission(store.nextLevel) {
                        GameTitle(text: level.title, size: 30)
                        Text(level.kind.title)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Art.gold)
                    }
                }
                .padding(20)
            }
            .frame(height: 244)
            .clipped()

            VStack(alignment: .leading, spacing: 11) {
                if let level = CampaignCatalog.mission(store.nextLevel) {
                    Text(level.setup)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Art.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                GameButton(title: store.allCompleted ? "Replay final case" : "PLAY LEVEL \(store.nextLevel)",
                           icon: "play.fill", action: play)
            }
            .padding(15)
            .background(Art.blueDeep)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Art.edge.opacity(0.75), lineWidth: 2))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                quickAction(icon: "square.grid.3x3.fill", title: "LEVELS", detail: "Choose a case", color: Art.cyan, action: levels)
                quickAction(icon: "rosette", title: "RANK", detail: "Your progress", color: Art.gold, action: stats)
            }
            HStack(spacing: 10) {
                quickAction(icon: "person.crop.square.fill", title: "DETECTIVE", detail: "Customize", color: Art.gold, action: wardrobe)
                quickAction(icon: "person.2.fill", title: "MULTIPLAYER", detail: "Race a friend", color: Art.mint, action: multiplayer)
            }
            HStack(spacing: 10) {
                quickAction(icon: "person.2.fill", title: "FRIENDS", detail: "Online network", color: Art.cyan, action: friends)
                quickAction(icon: "bag.fill", title: "SHOP", detail: "Buy snippets", color: Art.gold, action: wardrobe)
            }
        }
    }

    private func quickAction(icon: String, title: String, detail: String,
                             color: Color, action: @escaping () -> Void) -> some View {
        Button {
            GameEffects.shared.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 27, weight: .heavy))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text(detail)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Art.faded)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .frame(minHeight: 96, alignment: .leading)
            .background(Art.blueDeep)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Art.edge.opacity(0.65), lineWidth: 1.5))
        }
        .buttonStyle(PressGameStyle())
    }

    private var progress: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    GameKicker(text: "YOUR CAMPAIGN", color: Art.cyan)
                    Spacer()
                    Text("\(store.levelsCompleted)%")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Art.gold)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Art.ink)
                        Capsule().fill(Art.gold)
                            .frame(width: proxy.size.width * store.progressFraction)
                    }
                }
                .frame(height: 13)
                Text(store.levelsCompleted == 0 ?
                     "Start your first case to unlock the next level." :
                     "\(store.levelsCompleted) solved — keep going!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Art.faded)
            }
        }
    }

    private var footer: some View {
        HStack {
            GameKicker(text: "SOLO CAMPAIGN · OFFLINE")
            Spacer()
            GameKicker(text: "VERSION \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.4")", color: Art.faded)
        }
    }
}

struct LevelSelectView: View {
    @ObservedObject var store: CampaignStore
    let launch: (Int) -> Void
    let back: () -> Void
    @State private var chosenEpisode = 0
    @State private var selectedReplayLevel: Int?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                ScreenHeader(title: "LEVEL SELECT", subtitle: "CHOOSE YOUR NEXT MYSTERY", back: back)
                episodePicker
                let episode = CampaignCatalog.episodes[chosenEpisode]
                ZStack(alignment: .bottomLeading) {
                    DistrictIllustration(episode: episode.id)
                    LinearGradient(colors: [.clear, Art.ink.opacity(0.92)],
                                   startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        GameKicker(text: "DISTRICT \(chosenEpisode + 1) OF 10", color: Art.gold)
                        GameTitle(text: episode.title, size: 27)
                        Text(episode.subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Art.faded)
                    }
                    .padding(19)
                }
                .frame(height: 146)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack {
                    GameKicker(text: "MISSIONS \(episode.startLevel)–\(episode.endLevel)")
                    Spacer()
                    Text("\(store.episodeCompleted(episode))/10 solved · \(store.perfectLevels(in: chosenEpisode))/7 perfect")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)], spacing: 11) {
                    ForEach(episode.startLevel...episode.endLevel, id: \.self) { index in
                        levelTile(index)
                    }
                }
                GameCard(accent: Art.gold) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 25))
                            .foregroundStyle(Art.cyan)
                        Text("To unlock the next district, complete all 10 cases and score 3 stars in at least 7 of them. Replay completed cases to improve your best score.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Art.faded)
                    }
                }
            }
            .frame(maxWidth: 580)
            .padding(18)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .onAppear { chosenEpisode = (store.nextLevel - 1) / 10 }
        .alert("LEVEL ALREADY COMPLETED", isPresented: Binding(
            get: { selectedReplayLevel != nil },
            set: { if !$0 { selectedReplayLevel = nil } }
        )) {
            Button("Replay for a better score") {
                if let level = selectedReplayLevel {
                    selectedReplayLevel = nil
                    launch(level)
                }
            }
            Button("Cancel", role: .cancel) { selectedReplayLevel = nil }
        } message: {
            if let level = selectedReplayLevel {
                Text("Level \(level) is already cleared with \(store.stars(for: level)) of 3 stars. Replay it to improve your rating. Your best result will be kept.")
            }
        }
    }

    private var episodePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(CampaignCatalog.episodes) { episode in
                    let unlocked = store.isUnlocked(episode.startLevel)
                    Button {
                        GameEffects.shared.tap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            chosenEpisode = episode.id
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: unlocked ? episode.symbol : "lock.fill")
                                .font(.system(size: 14, weight: .black))
                            Text("\(episode.id + 1)")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(chosenEpisode == episode.id ? Art.ink : unlocked ? Art.paper : Art.faded)
                        .frame(width: 68, height: 45)
                        .background(chosenEpisode == episode.id ? Art.gold : Art.blueDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13)
                            .stroke(Art.edge.opacity(0.55), lineWidth: 1))
                    }
                    .buttonStyle(PressGameStyle())
                    .accessibilityLabel("District \(episode.id + 1), \(episode.title)")
                }
            }
        }
    }

    private func levelTile(_ level: Int) -> some View {
        let item = CampaignCatalog.mission(level)!
        let earned = store.stars(for: level)
        let unlocked = store.isUnlocked(level)
        return Button {
            guard unlocked else { return }
            GameEffects.shared.tap()
            if earned > 0 {
                selectedReplayLevel = level
            } else {
                launch(level)
            }
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(String(format: "%02d", level))
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(unlocked ? Art.paper : Art.faded)
                    Spacer()
                    Image(systemName: !unlocked ? "lock.fill" : earned > 0 ? "checkmark.circle.fill" : "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(!unlocked ? Art.faded : earned > 0 ? Art.mint : Art.gold)
                }
                Text(item.title.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(unlocked ? Art.paper : Art.faded)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 31, alignment: .leading)
                StarStrip(earned: earned, size: 15)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(unlocked ? Art.blueDeep : Art.ink.opacity(0.80))
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17)
                .stroke(level == store.nextLevel ? Art.gold : Art.edge.opacity(0.44), lineWidth: level == store.nextLevel ? 2.5 : 1))
            .opacity(unlocked ? 1 : 0.52)
            .contentShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(PressGameStyle())
        .disabled(!unlocked)
        .accessibilityLabel("Level \(level), \(item.title), \(unlocked ? "unlocked" : "locked"), \(earned) stars")
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    let back: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                GameEffects.shared.tap()
                back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Art.paper)
                    .frame(width: 45, height: 45)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13)
                        .stroke(Art.edge.opacity(0.7), lineWidth: 1.5))
            }
            .buttonStyle(PressGameStyle())
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 3) {
                GameTitle(text: title, size: 24)
                GameKicker(text: subtitle)
            }
            Spacer(minLength: 0)
        }
    }
}
