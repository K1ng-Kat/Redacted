import SwiftUI
import UIKit

/// Cleaner social hub shared by iPhone and iPad. Supabase Auth/SQL is
/// deliberately separate from iCloud and the single-player save system.
struct DetectiveSocialHubView: View {
    @ObservedObject private var network = DetectiveSocialNetwork.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var section: Section = .friends
    @State private var showingAdd = false
    @State private var showingTaskForceForm = false
    @State private var friendCode = ""
    @State private var taskForceCode = ""
    @State private var taskForceName = ""
    @State private var forceMode = 0
    @State private var confirmingLeave = false

    let openMultiplayer: () -> Void

    private enum Section: String, CaseIterable {
        case friends = "FRIENDS"
        case taskForces = "TASK FORCE"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 13) {
                titleBar
                compactStatus
                if network.accountEmail == nil {
                    RedactedAccountCard()
                } else {
                    picker
                    if section == .friends {
                        friendsContent
                    } else {
                        taskForceContent
                    }
                }
                if !network.configured {
                    setupNotice
                } else if !network.message.isEmpty {
                    Text(network.message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: 540)
            .padding(.horizontal, 16)
            .padding(.top, 13)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .refreshable { await network.refresh() }
        .sheet(isPresented: $showingAdd) { addFriendSheet }
        .sheet(isPresented: $showingTaskForceForm) { taskForceForm }
        .confirmationDialog("Leave this Task Force?", isPresented: $confirmingLeave) {
            Button("Leave Task Force", role: .destructive) {
                Task { await network.leaveTaskForce() }
            }
        }
        .task {
            await network.connect()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(40)) }
                catch { break }
                guard !Task.isCancelled, scenePhase == .active else { continue }
                await network.refresh()
            }
        }
        .onChange(of: scenePhase) { _, next in
            if next == .active { Task { await network.refresh() } }
        }
    }

    private var titleBar: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                GameTitle(text: "DETECTIVE NETWORK", size: 26)
                GameKicker(text: "FRIENDS & TASK FORCES", color: Art.cyan)
            }
            Spacer(minLength: 0)
            Button {
                GameEffects.shared.tap()
                Task { await network.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(Art.paper)
                    .frame(width: 44, height: 44)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressGameStyle())
            .disabled(network.isBusy || !network.configured)
            .accessibilityLabel("Refresh detective network")
        }
    }

    private var compactStatus: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(network.connected ? Art.mint : Art.gold)
                .frame(width: 10, height: 10)
            Text(network.connected ? "CONNECTED" :
                     network.accountEmail == nil ? "SIGN IN REQUIRED" : "NETWORK NOT CONNECTED")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(network.connected ? Art.mint : Art.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 4)
            if network.connected {
                Text("\(network.onlineFriends.count) ONLINE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
            } else if network.isBusy {
                ProgressView().tint(Art.cyan)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 43)
        .background(Art.blueDeep.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases, id: \.self) { value in
                Button {
                    GameEffects.shared.tap()
                    withAnimation(.easeInOut(duration: 0.20)) { section = value }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: value == .friends ? "person.2.fill" : "shield.lefthalf.filled")
                            .font(.system(size: 15, weight: .bold))
                        Text(value.rawValue)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(section == value ? Art.ink : Art.paper)
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .background(section == value ? Art.gold : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PressGameStyle())
            }
        }
        .padding(4)
        .background(Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var friendsContent: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(network.onlineFriends.count) ONLINE NOW")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    Text("\(network.friends.count) detectives in your network")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Art.faded)
                }
                Spacer(minLength: 0)
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Art.ink)
                        .frame(width: 47, height: 47)
                        .background(Art.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PressGameStyle())
                .disabled(!network.connected)
                .accessibilityLabel("Add friend")
            }
            .padding(.horizontal, 2)

            if !network.requests.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    GameKicker(text: "REQUESTS · \(network.requests.count)", color: Art.gold)
                    ForEach(network.requests) { request in
                        HStack(spacing: 9) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundStyle(Art.cyan)
                            Text(request.alias)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Spacer()
                            Button("ACCEPT") {
                                Task { await network.respond(id: request.id, accept: true) }
                            }
                            .foregroundStyle(Art.gold)
                            .font(.system(size: 11, weight: .black))
                            .frame(minHeight: 44)
                            Button {
                                Task { await network.respond(id: request.id, accept: false) }
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(Art.faded)
                                    .frame(width: 36, height: 44)
                            }
                            .accessibilityLabel("Decline \(request.alias)'s request")
                        }
                        .padding(.horizontal, 12)
                        .background(Art.blueDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            if network.friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Art.cyan)
                    Text("BUILD YOUR DETECTIVE TEAM")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                        .multilineTextAlignment(.center)
                    Text("Share your code with a friend to see when they're online.")
                        .font(.system(size: 12))
                        .foregroundStyle(Art.faded)
                        .multilineTextAlignment(.center)
                    if network.connected {
                        GameButton(title: "ADD DETECTIVE", icon: "person.badge.plus") {
                            showingAdd = true
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(17)
                .background(Art.blueDeep)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                if !network.onlineFriends.isEmpty {
                    GameKicker(text: "AVAILABLE TO PLAY", color: Art.mint)
                    ForEach(network.onlineFriends) { friend in
                        friendRow(friend)
                    }
                }
                if !network.offlineFriends.isEmpty {
                    GameKicker(text: "OFFLINE", color: Art.faded)
                    ForEach(network.offlineFriends) { friend in
                        friendRow(friend)
                    }
                }
            }
            if network.connected { inviteStrip }
        }
    }

    private func friendRow(_ friend: OnlineDetective) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Art.blueLight)
                    .frame(width: 43, height: 43)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Art.paper)
                    }
                Circle()
                    .fill(friend.online ? Art.mint : Art.faded)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Art.blueDeep, lineWidth: 2))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.alias)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text(friend.online ? "ONLINE NOW" : "OFFLINE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(friend.online ? Art.mint : Art.faded)
            }
            Spacer()
            if friend.online {
                Button {
                    GameEffects.shared.tap()
                    openMultiplayer()
                } label: {
                    Label("PLAY", systemImage: "gamecontroller.fill")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 41)
                        .background(Art.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PressGameStyle())
                .accessibilityLabel("Open 1v1 match lobby")
            }
        }
        .padding(11)
        .background(friend.online ? Art.blueLight.opacity(0.53) : Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13)
            .stroke(friend.online ? Art.mint.opacity(0.7) : Art.edge.opacity(0.4),
                    lineWidth: 1))
    }

    private var inviteStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 19))
                .foregroundStyle(Art.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR CODE")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(Art.faded)
                Text(network.myCode)
                    .font(.system(size: 17, weight: .black, design: .monospaced))
                    .foregroundStyle(Art.paper)
            }
            Spacer()
            ShareLink(item: "Add me in REDACTED! My detective code: \(network.myCode)") {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Art.cyan)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Share friend code")
            Button {
                UIPasteboard.general.string = network.myCode
                GameEffects.shared.success()
            } label: {
                Label("COPY", systemImage: "doc.on.doc")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Art.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 41)
                    .background(Art.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PressGameStyle())
        }
        .padding(11)
        .background(Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var taskForceContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            if let force = network.taskForce {
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 11) {
                        GameKicker(text: force.isLeader ? "YOUR TASK FORCE · LEADER" : "YOUR TASK FORCE",
                                   color: Art.gold)
                        GameTitle(text: force.name, size: 25)
                        HStack {
                            Label("\(force.members.count)/20 DETECTIVES", systemImage: "person.3.fill")
                            Spacer()
                            Label("\(force.onlineCount) ONLINE", systemImage: "circle.fill")
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.mint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        HStack(spacing: 10) {
                            Text(force.code)
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundStyle(Art.paper)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = force.code
                                GameEffects.shared.success()
                            } label: {
                                Label("COPY", systemImage: "doc.on.doc")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Art.ink)
                                    .padding(.horizontal, 11)
                                    .frame(height: 42)
                                    .background(Art.gold)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PressGameStyle())
                        }
                        Text("Share this code to invite someone into your Task Force.")
                            .font(.system(size: 12))
                            .foregroundStyle(Art.faded)
                    }
                }
                GameKicker(text: "DETECTIVES", color: Art.cyan)
                ForEach(force.members) { member in
                    HStack(spacing: 9) {
                        Circle()
                            .fill(member.online ? Art.mint : Art.faded)
                            .frame(width: 11, height: 11)
                        Text(member.alias)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(Art.paper)
                        if member.leader {
                            Text("LEADER")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(Art.gold)
                        }
                        Spacer()
                        Text(member.online ? "ONLINE" : "OFFLINE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(member.online ? Art.mint : Art.faded)
                    }
                    .padding(12)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button("LEAVE TASK FORCE") { confirmingLeave = true }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Art.coral)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                VStack(spacing: 13) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 43, weight: .semibold))
                        .foregroundStyle(Art.gold)
                    GameTitle(text: "TASK FORCES", size: 25)
                    Text("Form a private squad of up to 20 detectives. Join with an invite code, see who's active, and investigate together.")
                        .font(.system(size: 13))
                        .foregroundStyle(Art.faded)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if network.connected {
                        GameButton(title: "CREATE OR JOIN", icon: "person.3.fill") {
                            showingTaskForceForm = true
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(Art.blueDeep)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var setupNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("NETWORK SETUP REQUIRED", systemImage: "server.rack")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Art.gold)
            Text("Friends and Task Forces use a private account-backed server, not iCloud. The app developer must connect the service before online accounts, invites, and activity can work.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Art.paper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var addFriendSheet: some View {
        ZStack {
            GameBackdrop()
            VStack(alignment: .leading, spacing: 14) {
                sheetHeading("ADD FRIEND", subtitle: "DETECTIVE INVITE CODE") {
                    showingAdd = false
                }
                TextField("8-CHARACTER CODE", text: $friendCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 23, weight: .black, design: .monospaced))
                    .foregroundStyle(Art.paper)
                    .padding(13)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: friendCode) { _, value in
                        friendCode = String(value.uppercased()
                            .filter { $0.isHexDigit }.prefix(8))
                    }
                GameButton(title: "SEND FRIEND REQUEST", icon: "person.badge.plus",
                           inactive: friendCode.count != 8 || network.isBusy) {
                    Task { await network.sendRequest(code: friendCode) }
                }
                if !network.message.isEmpty {
                    Text(network.message).font(.system(size: 12))
                        .foregroundStyle(Art.faded)
                }
                Spacer()
            }
            .frame(maxWidth: 510)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDetents([.medium, .large])
    }

    private var taskForceForm: some View {
        ZStack {
            GameBackdrop()
            VStack(alignment: .leading, spacing: 15) {
                sheetHeading("TASK FORCE", subtitle: "PRIVATE DETECTIVE SQUADS") {
                    showingTaskForceForm = false
                }
                Picker("Choose action", selection: $forceMode) {
                    Text("CREATE").tag(0)
                    Text("JOIN").tag(1)
                }
                .pickerStyle(.segmented)
                if forceMode == 0 {
                    TextField("TASK FORCE NAME", text: $taskForceName)
                        .onChange(of: taskForceName) { _, value in
                            taskForceName = String(value.prefix(32))
                        }
                } else {
                    TextField("8-CHARACTER JOIN CODE", text: $taskForceCode)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: taskForceCode) { _, value in
                            taskForceCode = String(value.uppercased()
                                .filter { $0.isHexDigit }.prefix(8))
                        }
                }
                GameButton(title: forceMode == 0 ? "CREATE TASK FORCE" : "JOIN TASK FORCE",
                           icon: "shield.fill",
                           inactive: network.isBusy || (forceMode == 0
                               ? taskForceName.trimmingCharacters(in: .whitespaces).count < 3
                               : taskForceCode.count != 8)) {
                    Task {
                        if forceMode == 0 {
                            await network.createTaskForce(name: taskForceName)
                        } else {
                            await network.joinTaskForce(code: taskForceCode)
                        }
                        if network.taskForce != nil { showingTaskForceForm = false }
                    }
                }
                if !network.message.isEmpty {
                    Text(network.message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Art.faded)
                }
                Spacer(minLength: 0)
            }
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 510)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDetents([.medium, .large])
    }

    private func sheetHeading(_ title: String, subtitle: String,
                              close: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                GameTitle(text: title, size: 24)
                GameKicker(text: subtitle, color: Art.cyan)
            }
            Spacer()
            Button("DONE", action: close)
                .foregroundStyle(Art.cyan)
                .font(.system(size: 13, weight: .black))
                .frame(minHeight: 44)
        }
    }
}
