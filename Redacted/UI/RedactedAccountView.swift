import SwiftUI

/// Branded, passwordless REDACTED ID flow. A code is sent by the configured
/// email provider and verified by Auth on the server—not by the iPhone.
struct RedactedAccountCard: View {
    @ObservedObject private var network = DetectiveSocialNetwork.shared
    @ObservedObject private var backup = RedactedAccountSave.shared
    @State private var showingAccount = false

    var body: some View {
        GameCard(accent: network.accountEmail == nil ? Art.cyan : Art.mint) {
            VStack(alignment: .leading, spacing: 12) {
                GameKicker(text: "REDACTED ID", color: Art.cyan)
                HStack(spacing: 13) {
                    Image(systemName: network.accountEmail == nil
                          ? "envelope.badge.shield.half.filled"
                          : "checkmark.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(network.accountEmail == nil ? Art.gold : Art.mint)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(network.accountEmail == nil
                             ? "SAVE YOUR DETECTIVE"
                             : "ACCOUNT CONNECTED")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Art.paper)
                        Text(network.accountEmail ?? "Sign in with a code sent to your email.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Art.faded)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                Text(network.accountEmail == nil
                     ? "One email. One six-digit code. No Apple ID, passwords, or iCloud required."
                     : backup.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Art.paper)
                    .fixedSize(horizontal: false, vertical: true)
                GameButton(title: network.accountEmail == nil
                           ? "SIGN IN / CREATE ACCOUNT" : "MANAGE REDACTED ID",
                           icon: "envelope.fill") {
                    showingAccount = true
                }
            }
        }
        .sheet(isPresented: $showingAccount) {
            RedactedAccountView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct RedactedAccountView: View {
    @ObservedObject private var network = DetectiveSocialNetwork.shared
    @ObservedObject private var backup = RedactedAccountSave.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var code = ""
    @State private var showingDelete = false
    @State private var deletePhrase = ""

    var body: some View {
        ZStack {
            GameBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    header

                    if network.accountEmail != nil {
                        signedInContent
                    } else {
                        loginContent
                    }

                    Text("REDACTED ID uses private email-code verification. Your email is used for sign-in and account recovery, not displayed to other players. Your campaign stays saved locally even if you sign out.")
                        .font(.system(size: 12))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 510)
                .padding(20)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete REDACTED ID permanently?",
                            isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete My REDACTED ID", role: .destructive) {
                Task { await network.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletes the online account, its backup, friends and Task Force membership. Local campaign progress remains on this device.")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                GameTitle(text: "REDACTED ID", size: 29)
                GameKicker(text: "YOUR DETECTIVE ACCOUNT", color: Art.cyan)
            }
            Spacer()
            Button("DONE") { dismiss() }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Art.cyan)
                .frame(minWidth: 62, minHeight: 44)
        }
    }

    private var loginContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            GameCard(accent: Art.gold) {
                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(Art.gold)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ONE EMAIL. ONE CODE.")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Text("Create an account or sign in to an existing one.")
                                .font(.system(size: 12))
                                .foregroundStyle(Art.faded)
                        }
                    }
                    if !network.configured {
                        Text("The REDACTED email service has not been connected by the developer. Verification emails cannot be sent yet.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Art.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if network.codeSentTo == nil {
                        Text("EMAIL ADDRESS")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Art.cyan)
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Art.paper)
                            .padding(14)
                            .background(Art.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Email address")
                        GameButton(title: network.isBusy ? "SENDING…" : "SEND VERIFICATION CODE",
                                   icon: "paperplane.fill",
                                   inactive: network.isBusy || !network.configured ||
                                       !email.contains("@")) {
                            Task { await network.sendEmailCode(to: email) }
                        }
                    } else {
                        Text("CODE SENT TO")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Art.cyan)
                        Text(network.codeSentTo ?? "")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Art.paper)
                            .textSelection(.enabled)
                        TextField("000000", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .font(.system(size: 30, weight: .black, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .tracking(7)
                            .foregroundStyle(Art.paper)
                            .padding(14)
                            .background(Art.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: code) { _, value in
                                code = String(value.filter(\.isNumber).prefix(6))
                            }
                            .accessibilityLabel("Six-digit email verification code")
                        GameButton(title: network.isBusy ? "VERIFYING…" : "VERIFY & SIGN IN",
                                   icon: "checkmark.shield.fill",
                                   inactive: network.isBusy || code.count != 6) {
                            Task { await network.verifyEmailCode(code) }
                        }
                        HStack(spacing: 10) {
                            Button("CHANGE EMAIL") {
                                network.cancelEmailCode()
                                code = ""
                            }
                            Button("RESEND CODE") {
                                if let address = network.codeSentTo {
                                    Task { await network.sendEmailCode(to: address) }
                                }
                            }
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.cyan)
                        .frame(maxWidth: .infinity, minHeight: 45)
                        Text("For security, resend is limited to once per minute. Codes expire according to the email server's settings.")
                            .font(.system(size: 11))
                            .foregroundStyle(Art.faded)
                    }
                    if !network.message.isEmpty {
                        Text(network.message)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Art.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var signedInContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            GameCard(accent: Art.mint) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 11) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Art.mint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EMAIL VERIFIED")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Text(network.accountEmail ?? "")
                                .font(.system(size: 12))
                                .foregroundStyle(Art.faded)
                                .textSelection(.enabled)
                        }
                        Spacer()
                    }
                    if !network.myCode.isEmpty {
                        Text("DETECTIVE CODE · \(network.myCode)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Art.cyan)
                    }
                    Text(backup.status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Art.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    if backup.needsSaveChoice {
                        Text("An account save already exists. Decide which copy to keep:")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Art.gold)
                        GameButton(title: "RESTORE ACCOUNT PROGRESS",
                                   icon: "icloud.and.arrow.down") {
                            backup.restoreAccountSave()
                        }
                        GameButton(title: "KEEP THIS DEVICE'S PROGRESS",
                                   icon: "iphone", color: Art.blueLight,
                                   bottom: Art.blueDeep) {
                            Task { await backup.keepDeviceSave() }
                        }
                        Text("Keeping this device replaces the account backup only after you confirm. Rewards aren't added together.")
                            .font(.system(size: 11))
                            .foregroundStyle(Art.faded)
                    } else {
                        GameButton(title: backup.syncing ? "BACKING UP…" : "BACK UP NOW",
                                   icon: "arrow.triangle.2.circlepath",
                                   inactive: backup.syncing) {
                            Task { await backup.syncNow() }
                        }
                        Button("CHECK ACCOUNT SAVE") {
                            Task { await backup.checkAgain() }
                        }
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Art.cyan)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            Button {
                Task { await network.signOut() }
            } label: {
                Label("SIGN OUT (KEEP LOCAL SAVE)", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Art.gold)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(PressGameStyle())

            GameCard(accent: Art.coral) {
                VStack(alignment: .leading, spacing: 10) {
                    GameKicker(text: "DELETE ACCOUNT", color: Art.coral)
                    Text("Delete your online account and its backup permanently. Your local campaign stays on this device.")
                        .font(.system(size: 12))
                        .foregroundStyle(Art.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("TYPE DELETE", text: $deletePhrase)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Art.paper)
                        .padding(12)
                        .background(Art.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("DELETE REDACTED ID") {
                        showingDelete = true
                    }
                    .disabled(deletePhrase.uppercased() != "DELETE")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Art.coral)
                    .frame(minHeight: 44)
                }
            }
        }
    }
}
