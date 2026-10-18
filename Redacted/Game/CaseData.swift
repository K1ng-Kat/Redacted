import Foundation

enum EvidenceCategory: String, Codable, CaseIterable {
    case document = "DOCUMENT"
    case system = "SYSTEM LOG"
    case physical = "PHYSICAL"
    case correspondence = "MESSAGE"

    var symbol: String {
        switch self {
        case .document: "doc.text"
        case .system: "terminal"
        case .physical: "shippingbox"
        case .correspondence: "envelope"
        }
    }
}

struct CaseEvidence: Identifiable, Hashable {
    let id: String
    let title: String
    let category: EvidenceCategory
    let locationID: String
    let time: String
    let summary: String
    let contents: String
    let significance: String
}

struct CaseLocation: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let description: String
}

struct InterviewPrompt: Identifiable {
    let id: String
    let question: String
    let reply: String
}

struct CaseSuspect: Identifiable {
    let id: String
    let name: String
    let position: String
    let code: String
    let initials: String
    let statement: String
    let questions: [InterviewPrompt]
}

struct CaseDeduction: Identifiable {
    let id: String
    let heading: String
    let question: String
    let requiredEvidence: [String]
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let wrongHint: String
}

enum CaseData {
    static let caseNumber = "001"
    static let title = "THE MISSING ARCHIVE"
    static let subtitle = "Northpoint Research · October 18 · 21:16"
    static let synopsis = "A sealed research drive vanished during a six-minute camera blackout. Three staff members were on site. The official report calls it a systems failure. Your job is to prove what happened."
    static let culpritID = "jules"

    static let locations: [CaseLocation] = [
        .init(id: "archive", title: "Archive Room", subtitle: "Floor B2 · Secure storage",
              symbol: "lock.doc", description: "The vault stayed locked through most of the incident. Start with the door and access records."),
        .init(id: "security", title: "Security Office", subtitle: "Floor B1 · Monitoring",
              symbol: "video", description: "Camera controls and staff credentials may explain the missing six minutes."),
        .init(id: "dispatch", title: "Dispatch Annex", subtitle: "Floor B1 · Internal mail",
              symbol: "shippingbox", description: "Small sealed parcels leave the building through an automated transfer system."),
        .init(id: "it", title: "IT & Break Room", subtitle: "Floor 1 · Technical support",
              symbol: "desktopcomputer", description: "Maintenance schedules and staff movements could confirm or break an alibi.")
    ]

    static let evidence: [CaseEvidence] = [
        .init(id: "access", title: "Vault Access Log", category: .system, locationID: "archive", time: "21:11–21:19",
              summary: "Two credentials were used around the disappearance.",
              contents: "21:11 — M14 (Archivist): ACCESS GRANTED\n21:12 — M14: EXIT CONFIRMED\n21:17 — S02 (Security): OVERRIDE ENABLED\n21:19 — S02: OVERRIDE RELEASED",
              significance: "An archivist left before the blackout ended, but a security-level override remained active."),
        .init(id: "door", title: "Door Weight Sensor", category: .system, locationID: "archive", time: "21:12–21:20",
              summary: "No carried object passed the main vault exit.",
              contents: "Main exit object scan:\n21:12–21:20 — 0 outbound objects above 200 g.\nMissing drive, sealed case: 740 g.\nSensor calibration: PASSED.",
              significance: "The drive likely left through a route other than the main archive door."),
        .init(id: "camera", title: "CCTV Interruption", category: .system, locationID: "security", time: "21:12–21:18",
              summary: "The archive feed went black for exactly six minutes.",
              contents: "Feed CAM-B2: MANUALLY SUSPENDED\nStart: 21:12:04\nResume: 21:18:09\nCommand source: SECURITY CONSOLE\nOperator token: S02\nElectrical supply: NORMAL.",
              significance: "The camera blackout was intentional, not a power failure."),
        .init(id: "roster", title: "Staff Credential List", category: .document, locationID: "security", time: "Updated 20:45",
              summary: "Maps staff names to security credentials.",
              contents: "M14 — ADA MERCER — Archive Supervisor\nN07 — NOAH REED — IT Technician\nS02 — JULES HART — Head of Security\n\nElevated console access: S02 only.",
              significance: "Only Jules Hart owned the credential associated with the manual camera command."),
        .init(id: "dispatch", title: "Transfer Tube Receipt", category: .physical, locationID: "dispatch", time: "21:16",
              summary: "A sealed tube shipment was routed out of the archive.",
              contents: "ROUTE: B2 ARCHIVE → RECORDS ANNEX\nSCAN TIME: 21:16:41\nWEIGHT: 0.74 kg\nCONTENTS: UNDECLARED\nAUTHORIZATION: S02\nSTATUS: ACCEPTED",
              significance: "The package's weight matches the missing drive and was approved with S02."),
        .init(id: "audit", title: "Internal Audit Warning", category: .correspondence, locationID: "dispatch", time: "18:03",
              summary: "A private warning about security budget records.",
              contents: "TO: Jules Hart\nSUBJECT: Irregular transfers\n\nOur auditors will examine the security department's vendor payments at 09:00 tomorrow. The encrypted research drive includes the original approvals. Preserve all related materials.\n\n— Finance Compliance",
              significance: "Jules had a motive: the missing drive held records under investigation."),
        .init(id: "maintenance", title: "Maintenance Calendar", category: .document, locationID: "it", time: "20:54",
              summary: "No camera outage was scheduled during the incident.",
              contents: "NORTHPOINT IT MAINTENANCE\n21:00–21:30 — No planned service\n22:00 — Network firmware restart\n22:30 — Backup verification\n\nTicket N07-441: OPEN / NOT STARTED",
              significance: "A scheduled systems restart cannot explain a 21:12 interruption."),
        .init(id: "coffee", title: "Canteen Transaction", category: .physical, locationID: "it", time: "21:14",
              summary: "An ordinary receipt, with an important timestamp.",
              contents: "NORTHPOINT CANTEEN — KIOSK A\n21:14:22\nORDER: 1 × BLACK COFFEE\nSTAFF BADGE: N07\nCCTV KIOSK-A: VERIFIED",
              significance: "Noah's canteen activity supports his alibi during the camera blackout.")
    ]

    static let suspects: [CaseSuspect] = [
        .init(id: "ada", name: "Ada Mercer", position: "Archive Supervisor", code: "M14", initials: "AM",
              statement: "I completed inventory and left the archive before the cameras cut out. I didn't touch the research drive.",
              questions: [
                .init(id: "ada1", question: "Why were you in the archive at 21:11?",
                      reply: "End-of-day inventory. My badge log shows I left at 21:12. Security told us not to return while they checked a supposed camera fault."),
                .init(id: "ada2", question: "Who knew where the drive was stored?",
                      reply: "All three of us knew the cabinet, but only Security could override its transfer tube after hours. Jules signed off on that policy.")
              ]),
        .init(id: "noah", name: "Noah Reed", position: "IT Technician", code: "N07", initials: "NR",
              statement: "It wasn't our scheduled maintenance. I was getting coffee when the cameras stopped.",
              questions: [
                .init(id: "noah1", question: "Could the IT restart have cut the cameras?",
                      reply: "No. That job was scheduled for ten. The security camera feed can be suspended locally without shutting down the network."),
                .init(id: "noah2", question: "Can anyone verify your whereabouts?",
                      reply: "The canteen kiosk scanned my badge at 21:14. Its separate camera was working, if you want to check.")
              ]),
        .init(id: "jules", name: "Jules Hart", position: "Head of Security", code: "S02", initials: "JH",
              statement: "A network glitch knocked out the feed. No objects left through the archive door. That's all I know.",
              questions: [
                .init(id: "jules1", question: "Why does S02 appear in the override records?",
                      reply: "S02 is a shared emergency code. I may have used it to restore the feed, but I didn't suspend anything."),
                .init(id: "jules2", question: "Did any packages leave the archive?",
                      reply: "Not to my knowledge. We were under lockdown, and I would have noticed a person carrying a case out.")
              ])
    ]

    static let deductions: [CaseDeduction] = [
        .init(id: "blackout", heading: "THE BLACKOUT", question: "What actually caused the cameras to go dark?",
              requiredEvidence: ["camera", "maintenance"],
              options: ["A scheduled network restart", "A deliberate security-console command", "A building-wide power failure"],
              correctIndex: 1,
              explanation: "The camera log records a manual S02 command, while the maintenance calendar rules out a scheduled restart.",
              wrongHint: "Compare the camera command source with the maintenance schedule."),
        .init(id: "escape", heading: "THE ROUTE", question: "How did the stolen drive leave the archive?",
              requiredEvidence: ["door", "dispatch"],
              options: ["Carried out of the front door", "Sent through the automated transfer tube", "Uploaded over the facility Wi-Fi"],
              correctIndex: 1,
              explanation: "The main exit detected no object, but a 740 g parcel was dispatched by tube at 21:16.",
              wrongHint: "The weight sensor and outbound transfer receipt tell the same story.")
    ]

    static func evidence(in locationID: String) -> [CaseEvidence] {
        evidence.filter { $0.locationID == locationID }
    }

    static func evidence(for id: String) -> CaseEvidence? {
        evidence.first { $0.id == id }
    }

    static func suspect(for id: String) -> CaseSuspect? {
        suspects.first { $0.id == id }
    }
}
