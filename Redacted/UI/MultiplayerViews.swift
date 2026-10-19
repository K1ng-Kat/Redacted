import AVFoundation
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

private struct QRInviteImage: View {
    let url: URL

    var body: some View {
        Group {
            if let image = makeQR(url.absoluteString) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(11)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .accessibilityLabel("QR invitation to join REDACTED multiplayer")
    }

    private func makeQR(_ text: String) -> UIImage? {
        let qr = CIFilter.qrCodeGenerator()
        qr.message = Data(text.utf8)
        qr.correctionLevel = "H"
        guard let output = qr.outputImage,
              let cg = CIContext().createCGImage(
                output.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
                from: output.extent.applying(CGAffineTransform(scaleX: 10, y: 10)))
        else { return nil }
        return UIImage(cgImage: cg)
    }
}

struct MultiplayerLobbyView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void
    @ObservedObject private var service = MultiplayerService.shared
    @State private var enteredCode = ""
    @State private var showingScanner = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                ScreenHeader(title: "MULTIPLAYER", subtitle: "2-PLAYER DETECTIVE RACE", back: back)

                GameCard(accent: Art.cyan) {
                    VStack(alignment: .leading, spacing: 8) {
                        GameKicker(text: "PRIVATE INVITE-ONLY ROOMS", color: Art.cyan)
                        Text("Two detectives. One mystery. First to solve all three clues wins. There are 1,000 unique case combinations. Your campaign levels and currency are unaffected.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Online connection and iCloud are required. Opponents join by room code or QR, not public matchmaking.")
                            .font(.system(size: 11))
                            .foregroundStyle(Art.faded)
                    }
                }

                switch service.phase {
                case .idle, .error:
                    GameButton(title: "CREATE PRIVATE MATCH", icon: "plus.circle.fill") {
                        Task { await service.hostRoom() }
                    }
                    GameCard(accent: Art.gold) {
                        VStack(alignment: .leading, spacing: 13) {
                            GameKicker(text: "JOIN A FRIEND", color: Art.gold)
                            TextField("6-CHARACTER ROOM CODE", text: $enteredCode)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 23, weight: .black, design: .monospaced))
                                .foregroundStyle(Art.paper)
                                .padding(13)
                                .background(Art.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Enter multiplayer room code")
                            GameButton(title: "JOIN MATCH", icon: "arrow.right.circle.fill",
                                       inactive: enteredCode.trimmingCharacters(in: .whitespaces).count != 6) {
                                Task { await service.joinRoom(enteredCode) }
                            }
                            GameButton(title: "SCAN INVITE QR", icon: "qrcode.viewfinder",
                                       color: Art.blueLight, bottom: Art.blueDeep) {
                                showingScanner = true
                            }
                        }
                    }

                case .hosting, .joining:
                    GameCard(accent: Art.cyan) {
                        ProgressView().tint(Art.gold)
                        Text(service.message)
                            .foregroundStyle(Art.paper)
                    }

                case .waiting:
                    GameCard(accent: Art.gold) {
                        VStack(spacing: 13) {
                            GameKicker(text: "YOUR PRIVATE ROOM", color: Art.gold)
                            Text(service.roomCode)
                                .font(.system(size: 41, weight: .black, design: .monospaced))
                                .tracking(2.5)
                                .foregroundStyle(Art.paper)
                                .minimumScaleFactor(0.7)
                                .textSelection(.enabled)
                            if let link = service.inviteURL {
                                QRInviteImage(url: link)
                                    .frame(width: 190, height: 190)
                                ShareLink(item: link) {
                                    Label("SHARE QR INVITE LINK", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(Art.gold)
                                        .frame(minHeight: 48)
                                }
                                Button("COPY ROOM CODE") {
                                    UIPasteboard.general.string = service.roomCode
                                    GameEffects.shared.tap()
                                }
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(Art.cyan)
                                .frame(minHeight: 44)
                            }
                            ProgressView().tint(Art.gold)
                            Text(service.message)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Art.faded)
                                .multilineTextAlignment(.center)
                            if !service.opponent.isEmpty {
                                Text("OPPONENT: \(service.opponent)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.mint)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    GameButton(title: "LEAVE ROOM", icon: "xmark", color: Art.blueLight,
                               bottom: Art.blueDeep) { service.leaveRoom() }

                case .playing, .won, .lost:
                    MultiplayerRaceView(service: service)
                        .id(service.roomCode)
                }
                if service.phase == .error {
                    GameCard(accent: Art.coral) {
                        Text(service.message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Art.paper)
                    }
                }
            }
            .frame(maxWidth: 560)
            .padding(18)
            .padding(.bottom, 35)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .sheet(isPresented: $showingScanner) {
            QRCodeScannerSheet { value in
                showingScanner = false
                if let url = URL(string: value),
                   url.scheme == "redacted-detective",
                   url.host == "join" {
                    let code = url.pathComponents.last ?? ""
                    enteredCode = code
                    Task { await service.joinRoom(code) }
                } else {
                    service.leaveRoom()
                }
            }
        }
        .onAppear {
            service.attach(store)
            service.activate()
            service.startPresence()
        }
    }
}

private struct MultiplayerRaceView: View {
    @ObservedObject var service: MultiplayerService
    @State private var step = 0
    @State private var chosen: Int?
    @State private var code = ""
    @State private var penalty = false
    @State private var message = ""

    private var mystery: MultiplayerMystery? { service.currentMystery }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let mystery {
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            GameKicker(text: "LIVE CASE · \(mystery.id + 1)/1000", color: Art.gold)
                            Spacer()
                            Text("\(min(3, step + 1))/3 CLUES")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Art.cyan)
                        }
                        GameTitle(text: mystery.name.uppercased(), size: 23)
                        Text(mystery.brief)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("RACING \(service.opponent)")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Art.mint)
                    }
                }
                if service.phase == .playing {
                    if step == 0 {
                        choices(title: "WHICH CLUE FITS THE CRIME?", options: mystery.evidence,
                                correct: mystery.correctEvidence)
                    } else if step == 1 {
                        GameCard(accent: Art.cyan) {
                            VStack(alignment: .leading, spacing: 11) {
                                GameKicker(text: "OPEN THE EVIDENCE ENVELOPE", color: Art.cyan)
                                Text("Enter the three-digit evidence number from the case brief.")
                                    .foregroundStyle(Art.paper)
                                TextField("3-DIGIT CODE", text: $code)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 26, weight: .black, design: .monospaced))
                                    .foregroundStyle(Art.paper)
                                    .padding(14)
                                    .background(Art.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onChange(of: code) { _, value in
                                        code = String(value.filter { $0.isNumber }.prefix(3))
                                    }
                                GameButton(title: "UNLOCK EVIDENCE", icon: "lock.open.fill",
                                           inactive: penalty || code.count != 3) {
                                    attempt(code == mystery.code)
                                }
                            }
                        }
                    } else {
                        choices(title: "WHO HAD THE REQUIRED ACCESS?",
                                options: mystery.suspects, correct: mystery.correctSuspect)
                    }
                    if !message.isEmpty {
                        Text(message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(penalty ? Art.coral : Art.mint)
                    }
                } else {
                    GameCard(accent: service.phase == .won ? Art.mint : Art.coral) {
                        VStack(spacing: 12) {
                            Image(systemName: service.phase == .won ? "trophy.fill" : "flag.checkered")
                                .font(.system(size: 52))
                                .foregroundStyle(service.phase == .won ? Art.gold : Art.coral)
                            GameTitle(text: service.phase == .won ? "CASE WON!" : "CASE FINISHED", size: 30)
                            Text(service.message)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Art.paper)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            GameButton(title: "EXIT MULTIPLAYER ROOM", icon: "xmark.circle",
                       color: Art.blueLight, bottom: Art.blueDeep) {
                service.leaveRoom()
            }
        }
    }

    private func choices(title: String, options: [String], correct: Int) -> some View {
        GameCard(accent: Art.cyan) {
            VStack(alignment: .leading, spacing: 9) {
                GameKicker(text: title, color: Art.cyan)
                ForEach(options.indices, id: \.self) { index in
                    Button {
                        chosen = index
                        GameEffects.shared.tap()
                    } label: {
                        HStack(spacing: 12) {
                            Text(options[index])
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Art.paper)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: chosen == index ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(chosen == index ? Art.gold : Art.faded)
                        }
                        .padding(13)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Art.blueDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .stroke(chosen == index ? Art.gold : Art.edge, lineWidth: 1.5))
                    }
                    .buttonStyle(PressGameStyle())
                    .disabled(penalty)
                }
                GameButton(title: "SUBMIT CLUE", icon: "checkmark.shield",
                           inactive: chosen == nil || penalty) {
                    attempt(chosen == correct)
                }
            }
        }
    }

    private func attempt(_ right: Bool) {
        guard !penalty, service.phase == .playing else { return }
        if right {
            GameEffects.shared.success()
            message = "Correct. Move on to the next clue!"
            chosen = nil
            code = ""
            if step == 2 {
                Task { await service.finishMystery() }
            } else {
                step += 1
            }
        } else {
            GameEffects.shared.mistake()
            message = "Not supported by the evidence. 3-second penalty."
            penalty = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                chosen = nil
                penalty = false
                message = ""
            }
        }
    }
}

/// Friends is a primary app tab, so its list and presence information are
/// immediately visible rather than hidden behind a second navigation screen.
struct FriendsView: View {
    @ObservedObject var store: CampaignStore
    let openMultiplayer: () -> Void
    @ObservedObject private var service = MultiplayerService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingAddFriend = false
    @State private var newFriendCode = ""

    private var online: [FriendPresence] {
        service.onlineFriends.filter { $0.availability == .online }
    }
    private var offline: [FriendPresence] {
        service.onlineFriends.filter { $0.availability == .offline }
    }
    private var unknown: [FriendPresence] {
        service.onlineFriends.filter { $0.availability == .unavailable }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                overview

                if !service.requests.isEmpty {
                    pendingRequests
                }

                if store.progress.friendContacts.isEmpty {
                    emptyFriends
                } else {
                    friendsSection(
                        title: "ONLINE NOW", count: online.count,
                        friends: online, accent: Art.mint
                    )
                    if !offline.isEmpty {
                        friendsSection(
                            title: "OFFLINE", count: offline.count,
                            friends: offline, accent: Art.faded
                        )
                    }
                    if !unknown.isEmpty {
                        friendsSection(
                            title: "STATUS UNAVAILABLE", count: unknown.count,
                            friends: unknown, accent: Art.gold
                        )
                    }
                }
                inviteCard
                if let notice = service.friendsNotice {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Art.gold)
                        Text(notice)
                            .foregroundStyle(Art.paper)
                            .font(.system(size: 12, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text("Online status is based on recent app activity. It updates while Friends is open and when you pull down to refresh.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 17)
            .padding(.top, 16)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .refreshable { await service.refreshFriends() }
        .sheet(isPresented: $showingAddFriend) {
            addFriendSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            service.attach(store)
            await service.refreshFriends()
            // Automatic refresh stops when this tab disappears; no background
            // timer and no repeated fetches for a hidden page.
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(40))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                await service.refreshFriends()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await service.refreshFriends() }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                GameTitle(text: "FRIENDS", size: 30)
                GameKicker(text: "YOUR DETECTIVE NETWORK", color: Art.cyan)
            }
            Spacer(minLength: 0)
            Button {
                GameEffects.shared.tap()
                Task { await service.refreshFriends() }
            } label: {
                Group {
                    if service.isRefreshingFriends {
                        ProgressView().tint(Art.paper)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 19, weight: .black))
                    }
                }
                .foregroundStyle(Art.paper)
                .frame(width: 47, height: 47)
                .background(Art.blueDeep)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .stroke(Art.edge.opacity(0.65), lineWidth: 1.2))
            }
            .disabled(service.isRefreshingFriends)
            .accessibilityLabel("Refresh online friends and requests")
            Button {
                GameEffects.shared.tap()
                showingAddFriend = true
            } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(Art.ink)
                    .frame(width: 47, height: 47)
                    .background(Art.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .accessibilityLabel("Add a friend")
        }
    }

    private var overview: some View {
        GameCard(accent: online.isEmpty ? Art.cyan : Art.mint) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Art.mint.opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Art.mint)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(online.count) ONLINE NOW")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("\(store.progress.friendContacts.count) friends total")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Art.faded)
                }
                Spacer(minLength: 0)
                if !service.requests.isEmpty {
                    Text("\(service.requests.count) NEW")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Art.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(Art.gold)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let checked = service.lastFriendsRefresh {
                Text("Updated \(checked.formatted(date: .omitted, time: .shortened))  ·  Pull down to refresh")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Art.faded)
            } else if service.isRefreshingFriends {
                Text("Checking who's online…")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Art.faded)
            }
        }
    }

    private var pendingRequests: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("FRIEND REQUESTS", count: service.requests.count, color: Art.gold)
            ForEach(service.requests) { friend in
                GameCard(accent: Art.gold) {
                    HStack(spacing: 11) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 26))
                            .foregroundStyle(Art.gold)
                            .frame(width: 36, height: 40)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(friend.alias)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Text("Wants to be friends")
                                .font(.system(size: 11))
                                .foregroundStyle(Art.faded)
                        }
                        Spacer(minLength: 2)
                        Button {
                            GameEffects.shared.tap()
                            Task { await service.acceptFriend(friend) }
                        } label: {
                            Text("ACCEPT")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Art.ink)
                                .padding(.horizontal, 13)
                                .frame(height: 44)
                                .background(Art.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(PressGameStyle())
                    }
                }
            }
        }
    }

    private func sectionTitle(_ name: String, count: Int, color: Color) -> some View {
        HStack {
            GameKicker(text: name, color: color)
            Spacer()
            Text("\(count)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 2)
    }

    private func friendsSection(title: String, count: Int,
                                friends: [FriendPresence], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle(title, count: count, color: accent)
            if friends.isEmpty {
                GameCard {
                    HStack(spacing: 11) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Art.cyan)
                        Text("No friends online right now. Check back soon or invite someone to play.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                ForEach(friends) { friend in
                    friendRow(friend)
                }
            }
        }
    }

    private func friendRow(_ friend: FriendPresence) -> some View {
        let isOnline = friend.availability == .online
        let tone = isOnline ? Art.mint :
                   friend.availability == .unavailable ? Art.gold : Art.faded
        return HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Art.blueLight)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Art.paper)
                    }
                Circle()
                    .fill(tone)
                    .frame(width: 15, height: 15)
                    .overlay(Circle().stroke(Art.blueDeep, lineWidth: 3))
                    .offset(x: 1, y: 1)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(friend.alias)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 6) {
                    Image(systemName: isOnline ? "circle.fill" :
                          friend.availability == .unavailable ? "questionmark.circle.fill" : "moon.fill")
                        .font(.system(size: 9, weight: .black))
                    Text(friend.availability.label)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(tone)
            }
            Spacer(minLength: 1)
            if isOnline {
                Button {
                    GameEffects.shared.tap()
                    openMultiplayer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gamecontroller.fill")
                        Text("PLAY")
                    }
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Art.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 42)
                    .background(Art.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(PressGameStyle())
                .accessibilityLabel("Open multiplayer to create a room for \(friend.alias)")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isOnline ? Art.blueLight.opacity(0.53) : Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(isOnline ? Art.mint.opacity(0.8) : Art.edge.opacity(0.48),
                    lineWidth: isOnline ? 2 : 1))
        .accessibilityElement(children: .contain)
    }

    private var emptyFriends: some View {
        GameCard(accent: Art.cyan) {
            VStack(spacing: 12) {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Art.cyan)
                Text("YOUR DETECTIVE TEAM STARTS HERE")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .multilineTextAlignment(.center)
                Text("Share your friend code or add another detective to see when they're online.")
                    .font(.system(size: 13))
                    .foregroundStyle(Art.faded)
                    .multilineTextAlignment(.center)
                GameButton(title: "ADD YOUR FIRST FRIEND",
                           icon: "person.badge.plus") {
                    showingAddFriend = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var inviteCard: some View {
        GameCard(accent: Art.cyan) {
            VStack(alignment: .leading, spacing: 11) {
                GameKicker(text: "INVITE FRIENDS", color: Art.cyan)
                Text("YOUR PERSONAL FRIEND CODE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Art.faded)
                HStack(spacing: 10) {
                    Text(service.playerID)
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundStyle(Art.paper)
                        .tracking(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                    Button {
                        UIPasteboard.general.string = service.playerID
                        GameEffects.shared.success()
                    } label: {
                        Label("COPY", systemImage: "doc.on.doc")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Art.ink)
                            .padding(.horizontal, 11)
                            .frame(height: 42)
                            .background(Art.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressGameStyle())
                }
                HStack(spacing: 11) {
                    ShareLink(item: "Add me as a friend on REDACTED! My detective friend code is \(service.playerID).") {
                        Label("SHARE CODE", systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Art.cyan)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Art.blueDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button {
                        showingAddFriend = true
                    } label: {
                        Label("ADD FRIEND", systemImage: "person.badge.plus")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Art.paper)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Art.blueLight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressGameStyle())
                }
            }
        }
    }

    private var addFriendSheet: some View {
        ZStack {
            GameBackdrop()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        GameTitle(text: "ADD FRIEND", size: 25)
                        GameKicker(text: "INVITE BY DETECTIVE CODE", color: Art.cyan)
                    }
                    Spacer()
                    Button("DONE") { showingAddFriend = false }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Art.cyan)
                        .frame(minWidth: 55, minHeight: 44)
                }
                Text("Ask your friend for their eight-character code from the Friends tab.")
                    .font(.system(size: 13))
                    .foregroundStyle(Art.paper)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("8-CHARACTER CODE", text: $newFriendCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textContentType(.oneTimeCode)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(Art.paper)
                    .padding(14)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Art.edge, lineWidth: 1))
                    .onChange(of: newFriendCode) { _, value in
                        newFriendCode = String(value.uppercased()
                            .filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
                            .prefix(8))
                    }
                    .submitLabel(.go)
                    .onSubmit { sendFriendRequest() }
                GameButton(title: "SEND FRIEND REQUEST",
                           icon: "person.crop.circle.badge.plus",
                           inactive: newFriendCode.count != 8) {
                    sendFriendRequest()
                }
                if let notice = service.friendsNotice {
                    Text(notice)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 500)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
    }

    private func sendFriendRequest() {
        guard newFriendCode.count == 8 else { return }
        GameEffects.shared.tap()
        Task { await service.requestFriend(newFriendCode) }
    }
}

/// Compatible with older iPads: AVCapture metadata QR scanning (no LiDAR or
/// VisionKit DataScanner dependency).
struct QRCodeScannerSheet: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onScan = onScan
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {}
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var hasScanned = false
    private let preview = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let label = UILabel()
        label.text = "POINT CAMERA AT REDACTED QR CODE"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 15)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 35)
        ])
        Task { @MainActor in
            let approved = await AVCaptureDevice.requestAccess(for: .video)
            guard approved else {
                label.text = "CAMERA ACCESS NEEDED IN SETTINGS"
                return
            }
            self.startCapture()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }

    private func startCapture() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        preview.session = session
        preview.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preview, at: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard let code = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue
        else { return }
        Task { @MainActor in
            guard !self.hasScanned else { return }
            self.hasScanned = true
            self.onScan?(code)
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
}
