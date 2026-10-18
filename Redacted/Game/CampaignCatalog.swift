import Foundation

enum MissionKind: Int, Codable, CaseIterable {
    case findClue = 0, timeline, keypad, contradiction, anomaly, escapeRoute, anagram, signal, connect, verdict

    var title: String {
        switch self {
        case .findClue: "SPOT THE CLUE"
        case .timeline: "REBUILD THE TIMELINE"
        case .keypad: "CRACK THE LOCK"
        case .contradiction: "CATCH THE LIE"
        case .anomaly: "FIND THE FAKE"
        case .escapeRoute: "FOLLOW THE ROUTE"
        case .anagram: "DECODE THE WORD"
        case .signal: "TUNE THE SIGNAL"
        case .connect: "CONNECT THE EVIDENCE"
        case .verdict: "NAME THE CULPRIT"
        }
    }

    var instruction: String {
        switch self {
        case .findClue: "Tap the suspicious item in the scene."
        case .timeline: "Tap the four events in the order they happened."
        case .keypad: "Enter the three-digit combination using the keypad."
        case .contradiction: "Choose the statement that disproves the claim."
        case .anomaly: "Spot the detail that doesn't belong."
        case .escapeRoute: "Choose the route that matches the evidence."
        case .anagram: "Tap the scrambled letters to restore the codeword."
        case .signal: "Slide to the correct frequency, then lock it in."
        case .connect: "Select TWO related pieces of evidence."
        case .verdict: "Review the clues and choose who is responsible."
        }
    }

    var symbol: String {
        switch self {
        case .findClue: "magnifyingglass"
        case .timeline: "clock.arrow.circlepath"
        case .keypad: "lock.fill"
        case .contradiction: "text.bubble.fill"
        case .anomaly: "square.on.square.dashed"
        case .escapeRoute: "point.topleft.down.curvedto.point.bottomright.up"
        case .anagram: "character.cursor.ibeam"
        case .signal: "waveform.path"
        case .connect: "link"
        case .verdict: "checkmark.shield.fill"
        }
    }
}

struct CampaignEpisode: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
    var startLevel: Int { id * 10 + 1 }
    var endLevel: Int { startLevel + 9 }
}

struct CampaignMission: Identifiable {
    let id: Int
    let episode: Int
    let title: String
    let setup: String
    let solution: String
    let decoys: [String]
    let hint: String
    let outcome: String
    var kind: MissionKind { MissionKind(rawValue: (id - 1) % 10)! }
    var isFinale: Bool { kind == .verdict }

    var choices: [String] {
        switch kind {
        case .timeline:
            let sorted = decoys + [solution]
            return [sorted[2], sorted[0], sorted[3], sorted[1]]
        case .connect:
            let pair = solution.components(separatedBy: " + ")
            guard pair.count == 2 else { return decoys + [solution] }
            return [decoys[0], pair[0], decoys[1], pair[1]]
        default:
            let slot = (id * 3 + 1) % 4
            var candidates = decoys
            candidates.insert(solution, at: slot)
            return candidates
        }
    }

    var correctIndex: Int { (id * 3 + 1) % 4 }

    var correctSequence: [Int] { [2, 1, 3, 0] }
    var pairIndices: Set<Int> { [1, 3] }
    var expectedFrequency: Double { Double(Int(solution) ?? 50) }
}

private struct EpisodeSeed {
    let title: String
    let subtitle: String
    let symbol: String
    let rows: String
}

enum CampaignCatalog {
    private static let authored: [EpisodeSeed] = [
        EpisodeSeed(title: "NIGHT SHIFT", subtitle: "Crimes after dark", symbol: "moon.stars.fill", rows: """
            The Empty Locker|A guard heard a metallic scrape outside the closed lab.|Bent locker hinge|Untouched clock|Wet umbrella|Security poster|Look near the locker that was forced open.|The twisted hinge reveals an unauthorized entry.
            Twenty Seconds Missing|Rebuild the sequence before the patrol vanished.|Patrol clocked in|Camera lost power|Back door opened|Guard returned|Start with the clock-in, then follow the outage and entry.|The guard was gone only after someone opened the back door.
            The Badge Number|The note reads: take the last three digits of locker 5819.|819|582|918|581|A locker number has four digits; the lock accepts the last three.|The hidden compartment opens at 819.
            An Impossible Alibi|The witness claims no trains ran after midnight.|A train arrived at 00:14|The platform was cold|The lights were dim|The ticket was blue|Which statement conflicts with the no-trains claim?|The train arrival proves the alibi false.
            The Wrong Uniform|All patrol jackets have silver stripes.|Gold-striped jacket|Silver badge|Silver sleeve|Silver zipper|Find the part that breaks the uniform rule.|Someone wore an imitation patrol jacket.
            Service Corridor|The suspect avoided cameras and used a staff-only path.|Maintenance tunnel|Main lobby|Glass elevator|Public stairs|Which route avoids public cameras?|The tunnel bypasses all lobby cameras.
            Silent Password|Letters on the desk read: TRACE, but are scrambled on the keypad.|TRACE|Footprints|Ink stain|Desk lamp|Rebuild the five-letter word from the desk note.|TRACE identifies the secret witness log.
            Radio Crackle|The distress log records a signal at exactly 35.|35|Weak static|Siren pulse|Noisy channel|Tune the dial to the recorded 35 mark.|The original distress broadcast becomes clear.
            Two Matching Prints|Which pair proves the guard touched the sealed door?|Guard fingerprint + Door scanner record|Train ticket|Coffee cup|Empty envelope|Link the matching fingerprint and scan report.|The print and scanner timestamp place the guard at the door.
            Midnight Verdict|Who tampered with the patrol recording?|Night Supervisor|Delivery Driver|Station Cleaner|Late Commuter|The supervisor controlled both the patrol rota and recorder.|The supervisor had access to both systems.
            """),
        EpisodeSeed(title: "THE HARBOR", subtitle: "Ships, fog and stolen cargo", symbol: "ferry.fill", rows: """
            The Broken Seal|A container arrives with its tamper tag cut.|Cut cable seal|Cargo manifest|Anchor chain|Safety helmet|Inspect the object showing forced access.|The snapped seal proves the container was opened.
            Before the Fog|Put the dock events back into chronological order.|Ship moored|Customs scanned cargo|Crane moved crate|Fog signal sounded|The crane cannot move cargo before the ship docks.|The crate moved before the fog closed the port.
            Container 6247|The damaged label gives the four digits 6247; the pad wants the last three.|247|624|426|762|Use the final three digits printed on the container.|The lock responds to 247.
            The Captain's Claim|The captain says the vessel never changed course.|Navigation log shows a westward turn|The sea was calm|The deck was wet|The crew ate dinner|Find the entry contradicting a constant course.|The recorded turn proves a route diversion.
            The Fake Manifest|All official crates carry a blue customs label.|Red customs label|Blue tape|Blue barcode|Blue customs stamp|Identify the one label that does not match.|The red label was printed by an impostor.
            Under the Pier|The smugglers chose a route hidden from harbor floodlights.|Drainage culvert|Passenger terminal|Watchtower walkway|Customs gate|Select the concealed route beneath the docks.|The culvert connects the pier to the warehouse.
            Captain's Cipher|A flag message spells ANCHOR in scrambled letters.|ANCHOR|Salt on rope|Lighthouse|Ship bell|Arrange the flag letters into the shipboard word.|ANCHOR points to the abandoned mooring.
            Buoy Frequency|The missing vessel transmitted on channel 60.|60|Rough waves|Blue signal|Radio noise|Set the tuner to channel 60.|The lost transmission identifies the vessel.
            Saltwater Evidence|Connect the two clues proving the crate went into the water.|Salt crystals + Submerged crate photo|Oil receipt|Dry glove|Closed office|Choose the trace and image that prove water exposure.|Together the salt and image reveal a hidden drop.
            Harbor Master|Who approved the false container release?|Port Dispatcher|Ferry Passenger|Dock Medic|Tour Guide|The dispatcher controls release codes and shipping records.|A forged dispatch order exposed the culprit.
            """),
        EpisodeSeed(title: "NEON MARKET", subtitle: "Counterfeits and digital trails", symbol: "bag.fill", rows: """
            The Fake Watch|A luxury stall sells a watch with a mismatched dial.|Misprinted dial|Price sticker|Shopping bag|Glass counter|Inspect the object whose details disagree.|The dial gives away the counterfeit.
            The Vanishing Order|Reconstruct how the overnight order disappeared.|Order placed|Payment cleared|Address changed|Parcel collected|Payment always follows the order, not delivery.|The address changed before collection.
            Register 9305|The cashier left a receipt number 9305; enter its last three digits.|305|930|593|503|Take the trailing three digits of the receipt.|The register unlocks with 305.
            Chatroom Lie|A seller says refunds were never requested.|A refund request logged at 18:02|A buyer said hello|Someone sent an emoji|A bot joined the chat|Find the message that disproves the seller.|The logged refund exposes a false statement.
            Logo Swap|The real brand uses a round stamp on every box.|Square stamp|Round seal|Round sticker|Round barcode|Spot the packaging feature that breaks the rule.|The square stamp reveals a forgery.
            Backstreet Courier|Choose the unmonitored passage used by the courier.|Old loading alley|Main escalator|Market entrance|Security checkpoint|Find the route without store surveillance.|The courier escaped through the rear alley.
            QR Scramble|A torn QR note contains the letters PIXEL.|PIXEL|Barcode label|Broken charger|Window display|Reassemble the five-letter recovery key.|PIXEL opens the vendor's archived listing.
            Scanner Drift|A hidden product scanner broadcasts at frequency 45.|45|Static chirp|Price alarm|Market music|Tune the scanner receiver to 45.|The scanner identifies the counterfeit supplier.
            Duplicate Accounts|Which two records show a seller made a fake identity?|Repeated device ID + Duplicate payout account|Receipt paper|Broken hanger|Shopping cart|Link the repeated hardware and matching payout.|Both accounts belong to one operator.
            Market Verdict|Who ran the counterfeit storefront?|Store Manager|Busker|Security Guard|Delivery Customer|The manager controlled listings and payout details.|The storefront's manager directed the fraud.
            """),
        EpisodeSeed(title: "SNOWBOUND", subtitle: "Secrets at an isolated mountain base", symbol: "snowflake", rows: """
            Tracks in Snow|A snowmobile leaves marks beside a locked hangar.|Fresh tire tracks|Frozen lantern|Weather vane|Broken mug|Inspect the fresh trace outside the hangar.|The tread matches a staff snowmobile.
            The Whiteout|Arrange the rescue station's events.|Storm warning issued|Ski lift halted|Supply shed opened|Rescue beacon activated|The warning came before the lift closed.|The shed was accessed in the blackout.
            Bunker 1742|An emergency crate is marked 1742. Use the last three digits.|742|174|217|471|The bunker keypad only takes three numbers.|The emergency crate opens at 742.
            A Broken Forecast|The operator claims visibility remained clear all night.|Sensor measured zero visibility at 22:10|Snow fell earlier|A lantern glowed|The heater was warm|Find what rules out clear weather.|The sensor contradicts the operator's account.
            Wrong Boot Print|Everyone on the expedition wears a zigzag tread.|Circular tread|Zigzag heel|Zigzag toe|Zigzag sole|Which boot did not belong to the expedition?|The outsider left a different print.
            Ice Tunnel|How did someone bypass the guarded cable station?|Abandoned ice passage|Public ski trail|Helicopter pad|Main lodge corridor|Find the disused route through the mountain.|A maintenance passage avoided the guard.
            Frozen Note|The frost-covered window has the letters GLINT.|GLINT|Ice pick|Blanket|Snow gauge|Unscramble the word scratched into the glass.|GLINT identifies a reflector near the stash.
            Avalanche Beacon|The missing team used beacon frequency 75.|75|Falling ice|Cold wind|Distant echo|Turn the beacon dial to 75.|The beacon pinpoints the snow cave.
            Two Snow Samples|What proves the gear came from the upper ridge?|Blue glacier dust + Ridge equipment tag|Hot cocoa|Hotel receipt|Newspaper|Connect the glacier dust to its tagged origin.|Both traces put the gear on the upper ridge.
            Mountain Verdict|Who rerouted the emergency supplies?|Expedition Quartermaster|Tourist|Ski Instructor|Weather Reporter|The quartermaster controlled reserve crates and routing.|A supply transfer was deliberately concealed.
            """),
        EpisodeSeed(title: "OLD QUARTER", subtitle: "Antique shops and forgotten passages", symbol: "building.columns.fill", rows: """
            The Missing Key|An antique shop's locked cabinet has pry marks.|Scratched brass lock|Pocket watch|Velvet cloth|Dusty lamp|Find the sign of tampering on the cabinet.|The lock was forced from the outside.
            After Closing|Put the museum's evening in order.|Gallery locked|Alarm armed|Window unlatched|Painting removed|The window was opened after security closed.|The thief entered after the alarm set.
            Shelf 4881|An antique catalog uses shelf number 4881. Keypad: last three digits.|881|488|184|814|Discard the first catalog digit.|The hidden drawer opens using 881.
            Curator's Story|The curator claims no one handled the vase after cleaning.|Restoration log signed at 19:40|The foyer was crowded|A clock chimed|A candle was lit|Find the later handling record.|The vase was moved after closing.
            The Forged Painting|Every original canvas bears a triangular backing mark.|Circular mark|Triangle stamp|Triangular pin|Triangle etching|Spot the detail that cannot belong to the original.|The backing on the displayed painting is fake.
            Secret Passage|Which path leads behind the secured gallery wall?|Hidden bookcase door|Front museum steps|Visitor elevator|Café entrance|Look for the concealed route in the old building.|The bookcase covers a forgotten passage.
            Restorer's Word|Five letters on a brush handle read BRUSH.|BRUSH|Canvas|Copper frame|Gallery map|Restore the letters etched on the handle.|BRUSH opens the conservation archive.
            Clockmaker's Radio|A remote clock transmitter is set at 25.|25|Ticking hands|Clock chime|Hollow bell|Match the transmitter's 25 mark.|The synchronized clocks reveal the timeline.
            Matching Wax|What ties the stolen letter to the archive drawer?|Red wax flake + Drawer seal imprint|Blue ink|Old receipt|Wooden chair|Link the broken wax to the exact seal impression.|The letter was removed from the sealed drawer.
            Old Quarter Verdict|Who replaced the exhibition piece?|Restoration Director|Street Musician|Museum Visitor|Tour Bus Driver|The director held both access keys and restoration logs.|The restoration director arranged the swap.
            """),
        EpisodeSeed(title: "SKYPORT", subtitle: "Flight manifests and rooftop pursuits", symbol: "airplane", rows: """
            The Luggage Tag|An unclaimed suitcase has a peeled destination label.|Torn luggage tag|Boarding sign|Taxi voucher|Flight brochure|Inspect the damaged item tied to the bag.|The tag reveals its original destination.
            Gate Change|Order the recorded departure events.|Passengers checked in|Gate reassigned|Security boarded plane|Aircraft departed|The gate changed after check-in but before boarding.|The gate swap allowed the stolen package aboard.
            Locker 3658|An airport storage locker reads 3658. Enter the last three.|658|365|836|583|Use the ending three digits of the locker ID.|Compartment 658 contains the transfer slip.
            Pilot's Contradiction|The pilot says flight 22 departed at 10:00.|Tower log shows takeoff at 10:37|Coffee was served|Weather was mild|Passengers applauded|Find the official event disproving the takeoff time.|The tower log establishes the true departure.
            Wrong Boarding Pass|All business passes on the flight have green edges.|Orange-edged pass|Green seat number|Green barcode|Green border|Find the pass with the incorrect edge color.|The false pass gave someone unauthorized access.
            Rooftop Escape|The suspect avoided the crowded concourse cameras.|Maintenance roof bridge|Passport checkpoint|Main arrivals hall|Terminal escalators|Which access path bypasses the public terminal?|The roof bridge connects two restricted buildings.
            Tower Cipher|Air traffic shorthand contains the letters CLOUD.|CLOUD|Runway marking|Headset|Ticket sleeve|Unscramble the five-letter tower word.|CLOUD names the archived weather feed.
            Radar Sweep|The diverted drone was tracked at frequency 85.|85|Pilot chatter|Static buzz|Engine noise|Tune the tracking receiver to 85.|The drone's hidden path appears on the scanner.
            Passport Pair|What establishes the suspect crossed the restricted gate?|Gate badge scan + Customs timestamp|Snack bag|Lost pen|Waiting chair|Link the access scan with the timed immigration record.|The paired records expose an unauthorized crossing.
            Skyport Verdict|Who forged the cargo clearance?|Freight Controller|Flight Attendant|Tourist|Taxi Driver|The freight controller signed the altered manifest.|The controller authorized the illegal shipment.
            """),
        EpisodeSeed(title: "THE GALLERY", subtitle: "Missing art and impossible illusions", symbol: "paintpalette.fill", rows: """
            A Blank Frame|A painting disappeared but left a shadow on the wall.|Fresh frame outline|Velvet rope|Gallery ticket|Wall clock|Inspect the mark showing a picture was removed.|The outline reveals the stolen work's size.
            Opening Night|Rebuild the last events before the auction.|Guests arrived|Auction began|Lights flickered|Sculpture vanished|The sculpture was still there at auction start.|The theft happened during the flicker.
            Catalogue 7216|A display catalogue lists 7216. The lock takes the final three.|216|721|672|167|Read the last three catalogue digits.|The locked plinth responds to 216.
            Painter's Lie|An artist says the blue canvas was never repainted.|Lab detected fresh cobalt pigment|The room had skylights|The frame was gold|A label was crooked|Find direct proof of recent paint.|A pigment test proves the canvas was altered.
            Signature Trick|The real artist always signs paintings in lower-right blue.|Upper-left red signature|Blue lower-right initials|Blue lower-right date|Blue lower-right flourish|Which signature placement is wrong?|The signature is placed where the artist never signed.
            Behind the Exhibit|Where could a thief move unseen between galleries?|Restoration crawlspace|Glass atrium|Ticket desk|Central staircase|Choose a path hidden from visitors and cameras.|The crawlspace links the two exhibit rooms.
            Museum Codeword|The exhibit catalog hides the word FRAME.|FRAME|Oil palette|Security rope|Gallery light|Unscramble the restoration password.|FRAME reveals the unlisted painting.
            Infrared Sensor|The empty display emitted a sensor tone at 40.|40|Soft footfalls|Gallery music|Distant alarm|Tune the handheld sensor to 40.|An infrared trace reveals when the case opened.
            Paint Evidence|What connects the suspect's sleeve to the stolen sculpture?|Marble dust + Sleeve fiber match|Ticket stub|Fresh flower|Camera lens|Join the marble trace with the fiber comparison.|The suspect handled the sculpture directly.
            Gallery Verdict|Who ordered the artwork substitution?|Exhibition Curator|School Visitor|Café Barista|Parking Attendant|The curator scheduled the unrecorded art transfer.|The curator engineered the fake exhibit.
            """),
        EpisodeSeed(title: "UNDERCITY", subtitle: "Tunnels, trains and secret systems", symbol: "tram.fill", rows: """
            The Broken Switch|A subway gate jammed after someone opened its panel.|Loose switch housing|Paper ticket|Route poster|Platform bench|Inspect the part that was physically altered.|The switch panel was deliberately opened.
            Train Sequence|Arrange the station incident timeline.|Train entered tunnel|Signal turned red|Switch changed track|Train stopped|The train reached the tunnel before the red signal.|The altered switch forced the train to stop.
            Panel 5413|A maintenance panel is numbered 5413. Use its last three digits.|413|541|354|135|Use the rightmost three numerals.|The control panel unlocks at 413.
            Conductor's Claim|The conductor says platform 4 stayed empty.|Camera caught a passenger at 23:21|A tunnel echoed|The ticket machine blinked|A station clock stopped|Identify a record contradicting the empty platform.|The camera shows a passenger was present.
            Trackside Mismatch|All maintenance doors are painted amber.|Blue maintenance door|Amber latch|Amber warning sign|Amber doorframe|Find the door that breaks the color standard.|The blue door is an unauthorized access point.
            Subway Detour|Choose the unguarded route into the signal room.|Service ventilation shaft|Passenger turnstiles|Ticket hall|Escalator bank|Which path never passes the ticket cameras?|The ventilation shaft bypassed the main entrance.
            Control Word|Scattered control-panel letters spell TRACK.|TRACK|Platform map|Cable reel|Train seat|Unscramble the five-letter panel password.|TRACK accesses the switch log.
            Tunnel Frequency|The emergency underground repeater uses channel 55.|55|Train whistle|Ventilation hum|Distant footsteps|Select frequency 55 on the repeater.|The signal exposes an emergency diversion.
            Metal Fragments|Which pair proves someone sabotaged the rail joint?|Fresh steel filings + Cut bolt head|Paper map|Broken umbrella|Street sign|Link the filings to the severed bolt.|The rail joint was dismantled by hand.
            Undercity Verdict|Who altered the tunnel switch schedule?|Signal Engineer|Train Passenger|Newspaper Vendor|Ticket Collector|The signal engineer held the only override permission.|The engineer issued the illegal route change.
            """),
        EpisodeSeed(title: "THE SIGNAL", subtitle: "Broadcasts, recordings and hidden voices", symbol: "antenna.radiowaves.left.and.right", rows: """
            The Cut Cable|A radio studio falls silent during a live interview.|Severed microphone cable|Studio chair|Coffee flask|Guest badge|Inspect what physically stopped the broadcast.|The microphone cable was cut deliberately.
            Broadcast Timeline|Reconstruct the failed transmission.|Host started show|Caller interrupted|Studio feed muted|Emergency tape played|The emergency tape only followed a muted live feed.|The caller's interruption preceded the shutdown.
            Frequency 8604|An engineer wrote transmitter ID 8604. Use the last three digits.|604|860|486|468|Drop the first digit of the transmitter ID.|The emergency transmitter accepts 604.
            Producer's Denial|The producer claims the episode was never edited.|Version log lists edit at 03:09|A fan wrote a letter|The studio was cold|The headset was missing|Find proof of an edit despite the denial.|A saved revision contradicts the producer.
            Waveform Mismatch|All genuine clips have a silent one-second lead-in.|Immediate loud start|Silent first second|Quiet waveform start|Blank initial timestamp|Which clip violates the original format?|The loud start marks a spliced recording.
            Hidden Studio|Where could audio be re-recorded without entering reception?|Basement voice booth|Public studio lobby|Ticketed auditorium|Glass stairwell|Choose the studio accessible without public entry.|The basement booth records directly to the archive.
            Audio Cipher|A backwards station ident hides the word VOICE.|VOICE|Vinyl sleeve|Headphones|Patch cable|Rebuild the five-letter station password.|VOICE identifies the hidden take.
            Find the Carrier|A pirate broadcast was sent on frequency 70.|70|High static|Music echo|Weak speaker|Tune the radio to carrier 70.|The signal points to a second transmitter.
            Two Audio Traces|Which pair proves a voice was recorded in the basement?|Basement hum + Voiceprint match|Radio chart|Plastic cup|Hallway map|Join the background noise and speaker identification.|The audio was recorded inside the basement booth.
            Signal Verdict|Who replaced the emergency announcement?|Broadcast Producer|Station Tourist|Delivery Rider|Canteen Worker|The producer had the master tape and editing access.|The producer replaced the original emergency message.
            """),
        EpisodeSeed(title: "THE BLACK FILE", subtitle: "A conspiracy inside the bureau", symbol: "lock.shield.fill", rows: """
            The Burned Dossier|An agent discovers a partly destroyed evidence folder.|Scorched report cover|Office plant|Filing cabinet key|Waiting-room chair|Inspect the object showing deliberate destruction.|The dossier was burned to hide a classified memo.
            The Last Meeting|Arrange the director's final recorded movements.|Director entered office|Unmarked call received|Vault alarm disabled|Classified file removed|The call preceded the alarm change.|The file disappeared after the alarm was bypassed.
            Director 9926|A sealed file is indexed 9926. The secure keypad needs the last three.|926|992|699|269|Read the final three digits of the index.|The sealed evidence archive opens at 926.
            Witness Protection|An official says the witness never left the building.|Elevator log shows exit at 02:11|Desk light was on|Coffee machine worked|Rain hit the windows|Find evidence disproving the witness's presence.|The exit record shows the witness had already left.
            Forged Clearance|Authentic bureau clearance stamps have a double border.|Single-border stamp|Double frame|Double watermark|Double foil edge|Choose the document with a counterfeit stamp.|The clearance form was fabricated.
            The Hidden Floor|Which passage reaches the secure records without badge readers?|Old service lift|Main executive lobby|Public lobby stairs|Reception corridor|Select a route bypassing the official badge system.|The service lift provides an unlogged entrance.
            Director's Cipher|The final notebook contains the scrambled word PROOF.|PROOF|Shredded photo|Locked drawer|Signal lamp|Reconstruct the director's five-letter instruction.|PROOF points investigators to the original evidence.
            Secret Channel|An intercepted bureau transmitter used channel 95.|95|Encrypted hiss|Fan noise|Telephone ring|Tune to secure frequency 95.|A final transmission reveals the conspiracy.
            The Final Connection|Which evidence links the false clearance to the hidden file?|Forged badge ID + Vault audit trail|Office lunch|Ripped envelope|Calendar note|Connect the badge identity with the access trail.|Both records identify one covert operator.
            The Black File Verdict|Who ordered the entire cover-up?|Deputy Director|Night Janitor|Courier|Visiting Lawyer|The deputy director signed the missing-file order.|The bureau's deputy director planned the cover-up.
            """)
    ]

    static let episodes: [CampaignEpisode] = authored.enumerated().map { index, episode in
        CampaignEpisode(id: index, title: episode.title, subtitle: episode.subtitle, symbol: episode.symbol)
    }

    static let levels: [CampaignMission] = {
        var output: [CampaignMission] = []
        for (episodeNumber, episode) in authored.enumerated() {
            for (slot, line) in episode.rows.split(separator: "\n").enumerated() {
                let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                precondition(fields.count == 8, "Campaign data missing fields at episode \(episodeNumber) stage \(slot)")
                output.append(CampaignMission(
                    id: episodeNumber * 10 + slot + 1,
                    episode: episodeNumber,
                    title: fields[0],
                    setup: fields[1],
                    solution: fields[2],
                    decoys: [fields[3], fields[4], fields[5]],
                    hint: fields[6],
                    outcome: fields[7]
                ))
            }
        }
        precondition(output.count == 100, "The campaign must contain 100 authored missions")
        return output
    }()

    static func mission(_ number: Int) -> CampaignMission? {
        guard (1...levels.count).contains(number) else { return nil }
        return levels[number - 1]
    }

    static func episode(_ number: Int) -> CampaignEpisode? {
        guard episodes.indices.contains(number) else { return nil }
        return episodes[number]
    }
}
