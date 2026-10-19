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

struct FriendsView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void
    @ObservedObject private var service = MultiplayerService.shared
    @State private var newFriendCode = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: "FRIENDS", subtitle: "PRIVATE DETECTIVE NETWORK", back: back)

                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 10) {
                        GameKicker(text: "YOUR DETECTIVE FRIEND CODE", color: Art.gold)
                        Text(service.playerID)
                            .font(.system(size: 35, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundStyle(Art.paper)
                            .textSelection(.enabled)
                        Text(service.alias)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Art.cyan)
                        Button {
                            UIPasteboard.general.string = service.playerID
                            GameEffects.shared.tap()
                        } label: {
                            Label("COPY FRIEND CODE", systemImage: "doc.on.doc")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(Art.gold)
                                .frame(minHeight: 44)
                        }
                        Text("No public username search or messaging. Only people you share your code with can request to add you.")
                            .font(.system(size: 12))
                            .foregroundStyle(Art.faded)
                    }
                }

                GameCard(accent: Art.cyan) {
                    VStack(alignment: .leading, spacing: 11) {
                        GameKicker(text: "ADD A DETECTIVE", color: Art.cyan)
                        TextField("8-CHARACTER FRIEND CODE", text: $newFriendCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(Art.paper)
                            .padding(12)
                            .background(Art.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        GameButton(title: "SEND FRIEND REQUEST", icon: "person.crop.circle.badge.plus",
                                   inactive: newFriendCode.count != 8) {
                            Task { await service.requestFriend(newFriendCode) }
                        }
                    }
                }
                if !service.requests.isEmpty {
                    GameKicker(text: "FRIEND REQUESTS", color: Art.gold)
                    ForEach(service.requests) { friend in
                        GameCard(accent: Art.gold) {
                            HStack {
                                Text(friend.alias)
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(Art.paper)
                                Spacer()
                                Button("ACCEPT") {
                                    Task { await service.acceptFriend(friend) }
                                }
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Art.mint)
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }
                GameKicker(text: "YOUR FRIENDS · \(store.progress.friendContacts.count)",
                           color: Art.cyan)
                if service.onlineFriends.isEmpty {
                    GameCard {
                        Text("No added friends yet. Share your code to connect.")
                            .font(.system(size: 13))
                            .foregroundStyle(Art.faded)
                    }
                }
                ForEach(service.onlineFriends) { friend in
                    GameCard(accent: friend.online ? Art.mint : Art.edge) {
                        HStack(spacing: 13) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Art.cyan)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.alias)
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(Art.paper)
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(friend.online ? Art.mint : Art.faded)
                                        .frame(width: 9, height: 9)
                                    Text(friend.online ? "ONLINE" : "OFFLINE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(friend.online ? Art.mint : Art.faded)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                Text(service.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Art.faded)
                GameButton(title: "REFRESH FRIENDS", icon: "arrow.clockwise",
                           color: Art.blueLight, bottom: Art.blueDeep) {
                    Task { await service.refreshFriends() }
                }
            }
            .frame(maxWidth: 550)
            .padding(18)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .task {
            service.attach(store)
            await service.refreshFriends()
        }
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
