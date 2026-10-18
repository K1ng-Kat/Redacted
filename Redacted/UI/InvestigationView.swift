import SwiftUI

private enum InvestigationTab: String, CaseIterable, Identifiable {
    case desk = "Desk"
    case scenes = "Scenes"
    case evidence = "Evidence"
    case people = "People"
    case theory = "Theory"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .desk: "square.grid.2x2"
        case .scenes: "mappin.and.ellipse"
        case .evidence: "doc.text.magnifyingglass"
        case .people: "person.2"
        case .theory: "point.3.connected.trianglepath.dotted"
        }
    }
}

struct InvestigationView: View {
    @ObservedObject var store: InvestigationStore
    let leaveCase: () -> Void

    @State private var tab: InvestigationTab = .desk
    @State private var inspectedEvidence: CaseEvidence?
    @State private var interviewedSuspect: CaseSuspect?
    @State private var showFinale = false
    @State private var showAccusations = false
    @State private var showFeedback = false
    @State private var feedbackTitle = ""
    @State private var feedbackText = ""

    var body: some View {
        ZStack {
            RedactedBackdrop()

            VStack(spacing: 0) {
                topBar
                FileRule()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        switch tab {
                        case .desk: deskContent
                        case .scenes: scenesContent
                        case .evidence: evidenceContent
                        case .people: peopleContent
                        case .theory: theoryContent
                        }
                    }
                    .frame(maxWidth: 630)
                    .padding(.horizontal, 20)
                    .padding(.top, 25)
                    .padding(.bottom, 35)
                    .frame(maxWidth: .infinity)
                }
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $inspectedEvidence) { evidence in
            EvidenceDetail(evidence: evidence)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $interviewedSuspect) { suspect in
            SuspectInterview(suspect: suspect, store: store)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFinale) {
            CaseEnding(store: store)
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Make your accusation", isPresented: $showAccusations,
                            titleVisibility: .visible) {
            ForEach(CaseData.suspects) { suspect in
                Button(suspect.name) { makeAccusation(suspect.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your final accusation will be checked against the evidence. Incorrect accusations are recorded, but won't end the game.")
        }
        .alert(feedbackTitle, isPresented: $showFeedback) {
            Button("Continue investigating", role: .cancel) {}
        } message: {
            Text(feedbackText)
        }
    }

    private var topBar: some View {
        HStack(spacing: 13) {
            Button {
                Feedback.tap()
                leaveCase()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Noir.ivory)
                    .frame(width: 40, height: 40)
                    .background(Noir.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Return to main menu")

            VStack(alignment: .leading, spacing: 4) {
                Text("CASE 001")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Noir.ivory)
                FileLabel(text: "Northpoint · Classified", color: Noir.muted)
            }
            Spacer()
            StatusPill(title: store.state.caseClosed ? "Case closed" : "In progress",
                       highlighted: store.state.caseClosed)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(InvestigationTab.allCases) { item in
                Button {
                    Feedback.tap()
                    tab = item
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: tab == item ? .bold : .regular))
                            .frame(height: 24)
                        Text(item.rawValue)
                            .font(.system(size: 10, weight: tab == item ? .bold : .medium))
                    }
                    .foregroundStyle(tab == item ? Noir.accent : Noir.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == item ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 5)
        .background(Noir.card)
        .overlay(alignment: .top) { FileRule() }
    }

    private var deskContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(kicker: "Investigation / 001", title: "The Missing Archive",
                           subtitle: "A locked room. A missing drive. Six minutes nobody can explain.")

            FileCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        FileLabel(text: "Confidential briefing", color: Noir.accent)
                        Spacer()
                        Image(systemName: "lock.shield")
                            .foregroundStyle(Noir.accent)
                    }
                    FileRule()
                    Text(CaseData.synopsis)
                        .font(.system(size: 15))
                        .foregroundStyle(Noir.ivory)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("Incident: 21:12–21:18")
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Noir.muted)
                }
            }

            FileCard {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        FileLabel(text: "Case completion")
                        Spacer()
                        Text("\(Int(store.progressFraction * 100))%")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(Noir.ivory)
                    }
                    ProgressTrack(progress: store.progressFraction)
                    HStack {
                        counter("\(store.evidenceCount)/8", title: "Evidence")
                        Spacer()
                        counter("\(store.interviewedCount)/3", title: "People")
                        Spacer()
                        counter("\(store.deductionCount)/2", title: "Deductions")
                    }
                }
            }

            SectionHeading(kicker: "Your assignment", title: "Objectives")
            FileCard {
                VStack(alignment: .leading, spacing: 14) {
                    objective("Search the four facility locations", done: store.evidenceCount == CaseData.evidence.count)
                    FileRule()
                    objective("Interview all three suspects", done: store.interviewedCount == CaseData.suspects.count)
                    FileRule()
                    objective("Reconstruct the blackout and escape route", done: store.deductionCount == 2)
                    FileRule()
                    objective("Identify who took the drive", done: store.state.caseClosed)
                }
            }

            if store.state.caseClosed {
                RedButton(text: "View case resolution", symbol: "checkmark.seal") {
                    showFinale = true
                }
            } else {
                RedButton(text: store.evidenceCount == 0 ? "Search the crime scene" : "Continue searching",
                          symbol: "magnifyingglass") {
                    tab = .scenes
                }
            }
        }
    }

    private func counter(_ value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Noir.ivory)
            FileLabel(text: title)
        }
    }

    private func objective(_ title: String, done: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle.dotted")
                .foregroundStyle(done ? Noir.green : Noir.muted)
                .font(.system(size: 19))
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(done ? Noir.ivory : Noir.muted)
            Spacer(minLength: 0)
        }
    }

    private var scenesContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(kicker: "Fieldwork", title: "Search Locations",
                           subtitle: "Tap an item to collect it, then inspect its details. Your discoveries are saved automatically.")
            ForEach(CaseData.locations) { location in
                FileCard {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 13) {
                            Image(systemName: location.symbol)
                                .font(.system(size: 24))
                                .foregroundStyle(Noir.accent)
                                .frame(width: 45, height: 45)
                                .background(Noir.accent.opacity(0.11))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(location.title)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Noir.ivory)
                                FileLabel(text: location.subtitle)
                            }
                            Spacer()
                            let items = CaseData.evidence(in: location.id)
                            StatusPill(title: "\(items.filter { store.hasEvidence($0.id) }.count)/\(items.count)")
                        }
                        Text(location.description)
                            .font(.system(size: 13))
                            .foregroundStyle(Noir.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        FileRule()
                        ForEach(CaseData.evidence(in: location.id)) { evidence in
                            Button {
                                store.discover(evidence.id)
                                Feedback.tap()
                                inspectedEvidence = evidence
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: store.hasEvidence(evidence.id) ? "checkmark.circle.fill" : "magnifyingglass")
                                        .foregroundStyle(store.hasEvidence(evidence.id) ? Noir.green : Noir.accent)
                                        .frame(width: 23)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(evidence.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Noir.ivory)
                                        FileLabel(text: store.hasEvidence(evidence.id) ? "Collected · Reopen" : "Unexamined · Inspect")
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Noir.muted)
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            if evidence.id != CaseData.evidence(in: location.id).last?.id {
                                FileRule()
                            }
                        }
                    }
                }
            }
        }
    }

    private var evidenceContent: some View {
        VStack(alignment: .leading, spacing: 17) {
            SectionHeading(kicker: "Evidence Locker", title: "Collected Files",
                           subtitle: "\(store.evidenceCount) of \(CaseData.evidence.count) findings secured.")
            if store.evidenceCount == 0 {
                emptyState(icon: "archivebox", title: "No evidence collected",
                           description: "Search a location to discover your first piece of evidence.")
                RedButton(text: "Search locations") { tab = .scenes }
            } else {
                ForEach(CaseData.evidence.filter { store.hasEvidence($0.id) }) { evidence in
                    Button {
                        Feedback.tap()
                        inspectedEvidence = evidence
                    } label: {
                        FileCard {
                            HStack(spacing: 14) {
                                Image(systemName: evidence.category.symbol)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Noir.accent)
                                    .frame(width: 44)
                                VStack(alignment: .leading, spacing: 7) {
                                    FileLabel(text: evidence.category.rawValue + " · " + evidence.time)
                                    Text(evidence.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Noir.ivory)
                                    Text(evidence.summary)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Noir.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 1)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Noir.muted)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var peopleContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(kicker: "Interview Room", title: "Persons of Interest",
                           subtitle: "Question every suspect. Their stories might not match the records.")
            ForEach(CaseData.suspects) { suspect in
                Button {
                    Feedback.tap()
                    interviewedSuspect = suspect
                } label: {
                    FileCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 13) {
                                Text(suspect.initials)
                                    .font(.system(size: 17, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(Noir.ivory)
                                    .frame(width: 53, height: 53)
                                    .background(Noir.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(suspect.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Noir.ivory)
                                    FileLabel(text: suspect.position + " · " + suspect.code)
                                }
                                Spacer()
                                let hasInterview = suspect.questions.contains { store.hasAsked($0.id) }
                                StatusPill(title: hasInterview ? "Interviewed" : "Unquestioned",
                                           highlighted: hasInterview)
                            }
                            Text("“\(suspect.statement)”")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundStyle(Noir.muted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                FileLabel(text: "Open interview transcript", color: Noir.accent)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Noir.accent)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var theoryContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(kicker: "Analysis Division", title: "Deduction Board",
                           subtitle: "Evidence matters more than intuition. Reconstruct events before naming a suspect.")
            ForEach(CaseData.deductions) { deduction in
                deductionPanel(deduction)
            }

            FileCard(highlighted: store.canAccuse) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        FileLabel(text: "Final determination", color: Noir.accent)
                        Spacer()
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(Noir.accent)
                    }
                    Text(store.state.caseClosed ? "CASE CLOSED" : "Who took the drive?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Noir.ivory)
                    Text(store.state.caseClosed
                         ? "You've established the truth. Your full case reconstruction is ready."
                         : "To accuse someone, collect at least six pieces of evidence, question each suspect, and solve both deductions.")
                        .font(.system(size: 13))
                        .foregroundStyle(Noir.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    RedButton(text: store.state.caseClosed ? "Read case conclusion" : "Accuse a suspect",
                              symbol: "hand.raised",
                              disabled: !store.canAccuse) {
                        Feedback.tap()
                        if store.state.caseClosed {
                            showFinale = true
                        } else {
                            showAccusations = true
                        }
                    }
                }
            }
        }
    }

    private func deductionPanel(_ deduction: CaseDeduction) -> some View {
        let ready = store.isDeductionReady(deduction)
        let solved = store.deductionIsSolved(deduction.id)
        return FileCard(highlighted: solved) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    FileLabel(text: deduction.heading, color: Noir.accent)
                    Spacer()
                    StatusPill(title: solved ? "Proven" : ready ? "Ready" : "Evidence required",
                               highlighted: solved)
                }
                Text(deduction.question)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Noir.ivory)
                    .fixedSize(horizontal: false, vertical: true)

                if solved {
                    Label("DEDUCTION VERIFIED", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Noir.green)
                    Text(deduction.explanation)
                        .font(.system(size: 13))
                        .foregroundStyle(Noir.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !ready {
                    Text("Find: " + deduction.requiredEvidence.compactMap { CaseData.evidence(for: $0)?.title }.joined(separator: " + "))
                        .font(.system(size: 12))
                        .foregroundStyle(Noir.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(deduction.options.indices, id: \.self) { index in
                        Button {
                            Feedback.tap()
                            if store.submitDeduction(deduction, option: index) {
                                Feedback.success()
                            } else {
                                announce("Not supported by evidence", deduction.wrongHint)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Noir.accent)
                                Text(deduction.options[index])
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Noir.ivory)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Noir.muted)
                            }
                            .padding(13)
                            .background(Noir.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, description: String) -> some View {
        FileCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Noir.accent)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Noir.ivory)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Noir.muted)
            }
        }
    }

    private func makeAccusation(_ suspectID: String) {
        if store.accuse(suspectID) {
            Feedback.success()
            showFinale = true
        } else {
            announce("Accusation not proven", "That person's story does not fit all the evidence. Recheck the S02 credential, the transfer receipt, and the audit warning.")
        }
    }

    private func announce(_ title: String, _ description: String) {
        feedbackTitle = title
        feedbackText = description
        showFeedback = true
    }
}

private struct EvidenceDetail: View {
    let evidence: CaseEvidence

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        FileLabel(text: "Evidence / Secured", color: Noir.accent)
                        Spacer()
                        StatusPill(title: evidence.category.rawValue)
                    }
                    SectionHeading(kicker: "Evidence file · " + evidence.time,
                                   title: evidence.title, subtitle: evidence.summary)
                    FileCard {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: evidence.category.symbol)
                                    .foregroundStyle(Noir.accent)
                                FileLabel(text: "Original record")
                                Spacer()
                                Image(systemName: "lock.shield")
                                    .foregroundStyle(Noir.muted)
                            }
                            FileRule()
                            Text(evidence.contents)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Noir.ivory)
                                .lineSpacing(6)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    FileCard(highlighted: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            FileLabel(text: "Detective's note", color: Noir.accent)
                            Text(evidence.significance)
                                .font(.system(size: 14))
                                .foregroundStyle(Noir.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: 620)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SuspectInterview: View {
    let suspect: CaseSuspect
    @ObservedObject var store: InvestigationStore

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeading(kicker: "Interview / " + suspect.code, title: suspect.name,
                                   subtitle: suspect.position)
                    FileCard {
                        VStack(alignment: .leading, spacing: 12) {
                            FileLabel(text: "Initial statement", color: Noir.accent)
                            Text("“\(suspect.statement)”")
                                .font(.system(size: 15))
                                .foregroundStyle(Noir.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    SectionHeading(kicker: "Questioning", title: "Transcript")
                    ForEach(suspect.questions) { prompt in
                        FileCard(highlighted: store.hasAsked(prompt.id)) {
                            VStack(alignment: .leading, spacing: 13) {
                                FileLabel(text: "Detective")
                                Text(prompt.question)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Noir.ivory)
                                    .fixedSize(horizontal: false, vertical: true)
                                if store.hasAsked(prompt.id) {
                                    FileRule()
                                    FileLabel(text: suspect.name, color: Noir.accent)
                                    Text(prompt.reply)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Noir.ivory)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    RedButton(text: "Ask question", symbol: "bubble.left") {
                                        Feedback.tap()
                                        store.ask(prompt.id)
                                    }
                                }
                            }
                        }
                    }
                    FileLabel(text: "All answers are added to this local interview transcript.")
                }
                .frame(maxWidth: 620)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct CaseEnding: View {
    @ObservedObject var store: InvestigationStore

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        FileLabel(text: "Investigation terminated", color: Noir.green)
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Noir.green)
                    }
                    Text("CASE\nCLOSED.")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(Noir.ivory)
                        .tracking(-1)
                    FileCard(highlighted: true) {
                        VStack(alignment: .leading, spacing: 13) {
                            FileLabel(text: "Responsible party", color: Noir.accent)
                            Text("JULES HART")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundStyle(Noir.ivory)
                            Text("Head of Security · Credential S02")
                                .font(.system(size: 13))
                                .foregroundStyle(Noir.muted)
                            FileRule()
                            Text("Jules manually suspended the archive cameras, authorized a 740 g tube shipment containing the drive, and used the supposed network outage as a cover story. The missing records concerned suspicious vendor payments in Jules's own department.")
                                .font(.system(size: 14))
                                .foregroundStyle(Noir.ivory)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    SectionHeading(kicker: "Reconstruction", title: "What really happened")
                    FileCard {
                        VStack(alignment: .leading, spacing: 16) {
                            timeline("21:12", "Ada leaves the vault. A manual S02 command cuts the archive feed.")
                            FileRule()
                            timeline("21:16", "A sealed 740 g parcel leaves by transfer tube, not the guarded exit.")
                            FileRule()
                            timeline("21:18", "The cameras return; the theft is disguised as a routine fault.")
                            FileRule()
                            timeline("NEXT DAY", "The missing drive would have revealed irregular security payments.")
                        }
                    }
                    FileCard {
                        VStack(alignment: .leading, spacing: 8) {
                            FileLabel(text: "Investigation record")
                            Text("\(store.evidenceCount) evidence items · \(store.interviewedCount) interviews · \(store.state.incorrectAccusations) incorrect accusations")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Noir.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Case 001 is marked solved and saved on your device.")
                                .font(.system(size: 12))
                                .foregroundStyle(Noir.muted)
                        }
                    }
                }
                .frame(maxWidth: 620)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func timeline(_ time: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(time)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(Noir.accent)
                .frame(width: 65, alignment: .leading)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Noir.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
