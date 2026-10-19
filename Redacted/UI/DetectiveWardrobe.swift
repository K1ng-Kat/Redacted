import SwiftUI

// The persisted IDs and prices are unchanged: an existing player's purchases,
// equipped cosmetics, and wallet remain valid after the visual overhaul.
enum CosmeticSlot: String, CaseIterable, Identifiable, Codable {
    case headwear, eyewear, badge, coat
    var id: String { rawValue }
    var label: String {
        switch self {
        case .headwear: "HEADWEAR"
        case .eyewear: "EYEWEAR"
        case .badge: "BADGES"
        case .coat: "OUTFITS"
        }
    }
    var symbol: String {
        switch self {
        case .headwear: "hat.widebrim.fill"
        case .eyewear: "eyeglasses"
        case .badge: "shield.lefthalf.filled"
        case .coat: "jacket.fill"
        }
    }
}

struct DetectiveCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let slot: CosmeticSlot
    let symbol: String  // UI category fallback only, never painted on the avatar
    let requiredRank: Int
    let snippetPrice: Int
    let crystalPrice: Int
    let tint: Color

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SnippetPack: Identifiable {
    let count: Int
    let coins: Int
    var id: Int { count }
    static let all: [SnippetPack] = [
        .init(count: 1, coins: 55),
        .init(count: 5, coins: 250),
        .init(count: 12, coins: 540)
    ]
}

enum CosmeticCatalog {
    static let all: [DetectiveCosmetic] = [
        .init(id: "hat_cap", name: "Patrol Cap", slot: .headwear, symbol: "baseball.cap.fill", requiredRank: 1, snippetPrice: 3, crystalPrice: 2, tint: Art.cyan),
        .init(id: "glasses_round", name: "Round Glasses", slot: .eyewear, symbol: "eyeglasses", requiredRank: 1, snippetPrice: 3, crystalPrice: 2, tint: Art.gold),
        .init(id: "badge_bronze", name: "Bronze Shield", slot: .badge, symbol: "shield.fill", requiredRank: 2, snippetPrice: 4, crystalPrice: 2, tint: Art.gold),
        .init(id: "coat_navy", name: "Navy Field Coat", slot: .coat, symbol: "jacket.fill", requiredRank: 3, snippetPrice: 5, crystalPrice: 3, tint: Art.cyan),
        .init(id: "hat_beret", name: "Shadow Beret", slot: .headwear, symbol: "graduationcap.fill", requiredRank: 4, snippetPrice: 6, crystalPrice: 3, tint: Art.coral),
        .init(id: "glasses_visor", name: "Cipher Visor", slot: .eyewear, symbol: "sunglasses.fill", requiredRank: 5, snippetPrice: 7, crystalPrice: 3, tint: Art.mint),
        .init(id: "badge_silver", name: "Silver Star", slot: .badge, symbol: "star.circle.fill", requiredRank: 6, snippetPrice: 8, crystalPrice: 4, tint: Art.paper),
        .init(id: "coat_crimson", name: "Crimson Jacket", slot: .coat, symbol: "jacket.fill", requiredRank: 8, snippetPrice: 9, crystalPrice: 4, tint: Art.coral),
        .init(id: "hat_fedora", name: "Black Fedora", slot: .headwear, symbol: "hat.widebrim.fill", requiredRank: 10, snippetPrice: 11, crystalPrice: 5, tint: Art.gold),
        .init(id: "glasses_night", name: "Night Optics", slot: .eyewear, symbol: "eyeglasses", requiredRank: 12, snippetPrice: 12, crystalPrice: 5, tint: Art.mint),
        .init(id: "badge_gold", name: "Gold Agency Crest", slot: .badge, symbol: "rosette", requiredRank: 15, snippetPrice: 15, crystalPrice: 6, tint: Art.gold),
        .init(id: "coat_ghost", name: "Ghost Agent Suit", slot: .coat, symbol: "person.fill", requiredRank: 17, snippetPrice: 17, crystalPrice: 7, tint: Art.paper),
        .init(id: "hat_director", name: "Director's Cap", slot: .headwear, symbol: "crown.fill", requiredRank: 20, snippetPrice: 20, crystalPrice: 8, tint: Art.gold),
        .init(id: "badge_director", name: "Director's Insignia", slot: .badge, symbol: "crown.fill", requiredRank: 19, snippetPrice: 24, crystalPrice: 9, tint: Art.gold),
        .init(id: "coat_royal", name: "Royal Operative", slot: .coat, symbol: "sparkles", requiredRank: 20, snippetPrice: 30, crystalPrice: 10, tint: Art.cyan)
,
        .init(id: "hat_beanie", name: "Midnight Beanie", slot: .headwear, symbol: "hat.widebrim.fill", requiredRank: 2, snippetPrice: 5, crystalPrice: 2, tint: Art.cyan),
        .init(id: "hat_newsboy", name: "Newsboy Cap", slot: .headwear, symbol: "hat.widebrim.fill", requiredRank: 5, snippetPrice: 7, crystalPrice: 3, tint: Art.gold),
        .init(id: "hat_visor", name: "Field Visor", slot: .headwear, symbol: "sun.max.fill", requiredRank: 7, snippetPrice: 9, crystalPrice: 4, tint: Art.mint),
        .init(id: "hat_winter", name: "Snow Patrol", slot: .headwear, symbol: "snowflake", requiredRank: 9, snippetPrice: 12, crystalPrice: 5, tint: Art.paper),
        .init(id: "hat_hood", name: "Covert Hood", slot: .headwear, symbol: "person.fill", requiredRank: 13, snippetPrice: 16, crystalPrice: 6, tint: Art.coral),
        .init(id: "hat_pilot", name: "Air Marshal", slot: .headwear, symbol: "airplane", requiredRank: 17, snippetPrice: 20, crystalPrice: 7, tint: Art.gold),
        .init(id: "glasses_amber", name: "Amber Shades", slot: .eyewear, symbol: "sunglasses.fill", requiredRank: 2, snippetPrice: 5, crystalPrice: 2, tint: Art.gold),
        .init(id: "glasses_monocle", name: "Inspector Lens", slot: .eyewear, symbol: "eyeglasses", requiredRank: 4, snippetPrice: 7, crystalPrice: 3, tint: Art.cyan),
        .init(id: "glasses_clear", name: "Clear Frames", slot: .eyewear, symbol: "eyeglasses", requiredRank: 6, snippetPrice: 9, crystalPrice: 3, tint: Art.paper),
        .init(id: "glasses_ruby", name: "Ruby Optics", slot: .eyewear, symbol: "sunglasses.fill", requiredRank: 9, snippetPrice: 12, crystalPrice: 4, tint: Art.coral),
        .init(id: "glasses_ice", name: "Frost Goggles", slot: .eyewear, symbol: "eyeglasses", requiredRank: 13, snippetPrice: 17, crystalPrice: 6, tint: Art.mint),
        .init(id: "glasses_holo", name: "Hologram Visor", slot: .eyewear, symbol: "eye.fill", requiredRank: 18, snippetPrice: 22, crystalPrice: 8, tint: Art.cyan),
        .init(id: "badge_compass", name: "Compass Crest", slot: .badge, symbol: "safari.fill", requiredRank: 3, snippetPrice: 6, crystalPrice: 3, tint: Art.gold),
        .init(id: "badge_case", name: "Case Citation", slot: .badge, symbol: "checkmark.seal.fill", requiredRank: 5, snippetPrice: 8, crystalPrice: 3, tint: Art.cyan),
        .init(id: "badge_onyx", name: "Onyx Shield", slot: .badge, symbol: "shield.fill", requiredRank: 8, snippetPrice: 11, crystalPrice: 4, tint: Art.paper),
        .init(id: "badge_diamond", name: "Diamond Citation", slot: .badge, symbol: "diamond.fill", requiredRank: 11, snippetPrice: 14, crystalPrice: 5, tint: Art.mint),
        .init(id: "badge_royal", name: "Royal Eagle", slot: .badge, symbol: "bird.fill", requiredRank: 15, snippetPrice: 19, crystalPrice: 7, tint: Art.gold),
        .init(id: "badge_neon", name: "Neon Emblem", slot: .badge, symbol: "sparkle", requiredRank: 20, snippetPrice: 27, crystalPrice: 9, tint: Art.cyan),
        .init(id: "coat_sand", name: "Sand Trench", slot: .coat, symbol: "jacket.fill", requiredRank: 2, snippetPrice: 5, crystalPrice: 2, tint: Art.gold),
        .init(id: "coat_evergreen", name: "Forest Ranger", slot: .coat, symbol: "jacket.fill", requiredRank: 5, snippetPrice: 8, crystalPrice: 3, tint: Art.mint),
        .init(id: "coat_noir", name: "Noir Detective", slot: .coat, symbol: "jacket.fill", requiredRank: 7, snippetPrice: 11, crystalPrice: 4, tint: Art.paper),
        .init(id: "coat_arctic", name: "Arctic Explorer", slot: .coat, symbol: "jacket.fill", requiredRank: 10, snippetPrice: 14, crystalPrice: 5, tint: Art.cyan),
        .init(id: "coat_sunset", name: "Sunset Agent", slot: .coat, symbol: "jacket.fill", requiredRank: 14, snippetPrice: 19, crystalPrice: 7, tint: Art.coral),
        .init(id: "coat_cipher", name: "Cipher Commander", slot: .coat, symbol: "jacket.fill", requiredRank: 19, snippetPrice: 27, crystalPrice: 9, tint: Art.gold)
    ]
    static func item(_ id: String?) -> DetectiveCosmetic? { all.first { $0.id == id } }
    static func items(in slot: CosmeticSlot) -> [DetectiveCosmetic] {
        all.filter { $0.slot == slot }
            .sorted { $0.requiredRank == $1.requiredRank
                ? $0.snippetPrice < $1.snippetPrice
                : $0.requiredRank < $1.requiredRank }
    }
}

/// All item previews and every in-game appearance now share one geometric
/// avatar painter. Existing equipped IDs remain compatible.
struct DetectiveCharacter: View {
    @ObservedObject var store: CampaignStore
    var size: CGFloat = 140
    var previewCosmetic: DetectiveCosmetic? = nil
    var previewTheme: String? = nil

    @AppStorage("redacted.profile.theme") private var theme = "midnight"

    var body: some View {
        DetectiveAvatarArt(
            theme: previewTheme ?? theme,
            skin: store.skin,
            hair: store.hair,
            loadout: loadout,
            size: size
        )
    }

    private var loadout: [CosmeticSlot: String] {
        var equipment: [CosmeticSlot: String] = [:]
        for slot in CosmeticSlot.allCases {
            if let id = store.equippedCosmetic(in: slot) { equipment[slot] = id }
        }
        if let previewCosmetic {
            equipment[previewCosmetic.slot] = previewCosmetic.id
        }
        return equipment
    }
}

/// Four tabbed collections, one centered live character, focused item detail.
/// No decorative floating icons; what you preview is what you equip.
struct DetectiveWardrobeView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void

    @State private var slot: CosmeticSlot = .headwear
    @State private var selectedID = "hat_cap"
    @State private var showSnippetShop = false
    @State private var pendingItem: DetectiveCosmetic?
    @State private var payingCrystals = false
    @State private var showResetSlot = false
    @State private var notice: String?

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    private var selectedItem: DetectiveCosmetic? {
        CosmeticCatalog.items(in: slot).first { $0.id == selectedID }
            ?? CosmeticCatalog.items(in: slot).first
    }

    private var eligibleCount: Int {
        CosmeticCatalog.items(in: slot).filter { $0.requiredRank <= store.accountLevel }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: "STYLE LAB", subtitle: "BUILD YOUR DETECTIVE", back: back)
                playerPreview
                appearanceSection
                currencyStrip
                categoryPicker
                collectionGrid
                selectedDetail
                shopSection
                if let notice {
                    Text(notice)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Art.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .frame(maxWidth: 570)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 44)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .confirmationDialog("PERMANENTLY UNLOCK COSMETIC?",
                            isPresented: Binding(
                                get: { pendingItem != nil },
                                set: { if !$0 { pendingItem = nil } }
                            ), titleVisibility: .visible) {
            if let item = pendingItem {
                Button("Unlock \(item.name) for \(payingCrystals ? item.crystalPrice : item.snippetPrice) \(payingCrystals ? "crystals" : "snippets")") {
                    if store.unlockCosmetic(item, crystals: payingCrystals) {
                        GameEffects.shared.success()
                        notice = "\(item.name) permanently unlocked and equipped."
                    } else {
                        GameEffects.shared.mistake()
                        notice = "Purchase unavailable. Check your rank and balance."
                    }
                    pendingItem = nil
                }
            }
            Button("Cancel", role: .cancel) { pendingItem = nil }
        } message: {
            Text("The selected currency will be spent once. XP and detective rank never change when buying cosmetics.")
        }
    }

    private var playerPreview: some View {
        GameCard(accent: Art.cyan) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        GameKicker(text: "YOUR DETECTIVE", color: Art.cyan)
                        Text(store.rankTitle.uppercased())
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Art.paper)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    Text("RANK \(store.accountLevel)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Art.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Art.gold)
                        .clipShape(Capsule())
                }
                DetectiveCharacter(store: store, size: 215, previewCosmetic: selectedItem)
                    .frame(maxWidth: .infinity)
                    .accessibilityHint("Preview includes the selected item before buying or equipping it")
                HStack(spacing: 7) {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(Art.cyan)
                        .frame(width: 20, height: 20)
                    Text("LIVE TRY-ON · SELECT AN ITEM BELOW")
                        .foregroundStyle(Art.faded)
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    private var appearanceSection: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 12) {
                GameKicker(text: "YOUR LOOK  ·  FREE", color: Art.gold)
                Text("Skin tone")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Art.paper)
                HStack(spacing: 9) {
                    ForEach(DetectiveSkin.allCases) { shade in
                        Button {
                            store.setSkin(shade)
                            GameEffects.shared.tap()
                        } label: {
                            Circle()
                                .fill(shade.color)
                                .frame(width: 30, height: 30)
                                .frame(maxWidth: .infinity, minHeight: 45)
                                .background(store.skin == shade
                                            ? Art.blueLight : Art.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.skin == shade ? Art.gold : Art.edge,
                                            lineWidth: store.skin == shade ? 2.5 : 1))
                        }
                        .buttonStyle(PressGameStyle())
                        .accessibilityLabel("\(shade.label) skin")
                        .accessibilityAddTraits(store.skin == shade ? .isSelected : [])
                    }
                }
                Text("Hair style")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Art.paper)
                HStack(spacing: 7) {
                    ForEach(DetectiveHair.allCases) { style in
                        Button {
                            store.setHair(style)
                            GameEffects.shared.tap()
                        } label: {
                            Text(style.label)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(store.hair == style ? Art.ink : Art.paper)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(store.hair == style ? Art.gold : Art.blueDeep)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(PressGameStyle())
                    }
                }
            }
        }
    }

    // One two-column grid uses the same icon, padding and text dimensions as
    // the Detective Profile. No tiny crystal box or placeholder coin symbol.
    private var currencyStrip: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            GameCurrencyChip(kind: .xp, amount: store.accountXP)
            GameCurrencyChip(kind: .coins, amount: store.coins)
            GameCurrencyChip(kind: .snippets, amount: store.snippets)
            GameCurrencyChip(kind: .crystals, amount: store.crystals)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            GameKicker(text: "EQUIPMENT · \(eligibleCount) AVAILABLE", color: Art.gold)
            LazyVGrid(columns: columns, spacing: 9) {
                ForEach(CosmeticSlot.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            slot = option
                            selectedID = CosmeticCatalog.items(in: option).first?.id ?? ""
                            notice = nil
                        }
                        GameEffects.shared.tap()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: option.symbol)
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 29, height: 29, alignment: .center)
                            Text(option.label)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(slot == option ? Art.ink : Art.paper)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 57, alignment: .leading)
                        .background(slot == option ? Art.gold : Art.blueDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(slot == option ? Art.gold : Art.edge, lineWidth: 1.1))
                    }
                    .buttonStyle(PressGameStyle())
                    .accessibilityLabel(option.label)
                    .accessibilityAddTraits(slot == option ? .isSelected : [])
                }
            }
        }
    }

    private var collectionGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(CosmeticCatalog.items(in: slot)) { item in
                itemTile(item)
            }
        }
    }

    private func itemTile(_ item: DetectiveCosmetic) -> some View {
        let isOwned = store.ownedCosmetics.contains(item.id)
        let isEquipped = store.equippedCosmetic(in: item.slot) == item.id
        let rankLocked = store.accountLevel < item.requiredRank
        let selected = selectedItem?.id == item.id

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedID = item.id
                notice = nil
            }
            GameEffects.shared.tap()
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                ZStack(alignment: .bottomTrailing) {
                    DetectiveCharacter(store: store, size: 122, previewCosmetic: item)
                        .frame(maxWidth: .infinity)
                        .opacity(rankLocked ? 0.58 : 1)
                    Image(systemName: rankLocked ? "lock.fill"
                          : isEquipped ? "checkmark.circle.fill"
                          : isOwned ? "checkmark.seal.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(isEquipped || isOwned ? Art.mint : Art.gold)
                        .padding(6)
                        .background(Art.ink)
                        .clipShape(Circle())
                        .padding(5)
                }
                Text(item.name.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .topLeading)
                Text(isEquipped ? "EQUIPPED" :
                        isOwned ? "OWNED" :
                        rankLocked ? "RANK \(item.requiredRank) REQUIRED" :
                        "\(item.snippetPrice) SNIPPETS / \(item.crystalPrice) CRYSTALS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isEquipped ? Art.mint : Art.faded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Art.blueDeep)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? Art.gold : Art.edge,
                        lineWidth: selected ? 2.5 : 1))
        }
        .buttonStyle(PressGameStyle())
        .accessibilityLabel("\(item.name), \(rankLocked ? "locked" : isEquipped ? "equipped" : "select to preview")")
    }

    @ViewBuilder
    private var selectedDetail: some View {
        if let item = selectedItem {
            let owned = store.ownedCosmetics.contains(item.id)
            let equipped = store.equippedCosmetic(in: item.slot) == item.id
            let rankLocked = store.accountLevel < item.requiredRank

            GameCard(accent: owned ? Art.mint : rankLocked ? Art.edge : Art.gold) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            GameKicker(text: "SELECTED ITEM", color: Art.cyan)
                            Text(item.name.uppercased())
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            Text("REQUIRES DETECTIVE RANK \(item.requiredRank)")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundStyle(rankLocked ? Art.coral : Art.mint)
                        }
                        Spacer(minLength: 3)
                        Image(systemName: slot.symbol)
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(Art.gold)
                            .frame(width: 45, height: 45)
                            .background(Art.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if owned {
                        GameButton(title: equipped ? "CURRENTLY EQUIPPED" : "EQUIP THIS ITEM",
                                   icon: "checkmark.seal.fill", inactive: equipped) {
                            store.equipCosmetic(item)
                            GameEffects.shared.success()
                            notice = "\(item.name) is now equipped."
                        }
                        if equipped {
                            Button("REMOVE \(slot.label)") {
                                store.unequipCosmetic(slot: slot)
                                GameEffects.shared.tap()
                                notice = "Returned to the default \(slot.label.lowercased())."
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Art.cyan)
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    } else if rankLocked {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(Art.gold)
                            Text("Keep solving cases to unlock this item at Rank \(item.requiredRank).")
                                .foregroundStyle(Art.paper)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    } else {
                        Text("Unlock permanently with saved snippets or spend crystals now. Your XP and rank stay unchanged.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Art.faded)
                        HStack(spacing: 9) {
                            purchaseButton(item, useCrystals: false)
                            purchaseButton(item, useCrystals: true)
                        }
                    }
                }
            }
        }
    }

    private func purchaseButton(_ item: DetectiveCosmetic, useCrystals: Bool) -> some View {
        let price = useCrystals ? item.crystalPrice : item.snippetPrice
        let enough = useCrystals ? store.crystals >= price : store.snippets >= price
        return Button {
            payingCrystals = useCrystals
            pendingItem = item
            GameEffects.shared.tap()
        } label: {
            VStack(spacing: 5) {
                if useCrystals { CrystalIcon(size: 22) }
                else {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Art.cyan)
                }
                Text("\(price) \(useCrystals ? "CRYSTALS" : "SNIPPETS")")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(Art.ink)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(enough ? Art.gold : Art.edge, lineWidth: 1.5))
            .opacity(enough ? 1 : 0.5)
        }
        .buttonStyle(PressGameStyle())
        .disabled(!enough)
        .accessibilityLabel("Unlock \(item.name) for \(price) \(useCrystals ? "crystals" : "snippets")")
    }

    private var shopSection: some View {
        GameCard(accent: Art.gold) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { showSnippetShop.toggle() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            GameKicker(text: "SNIPPET EXCHANGE", color: Art.gold)
                            Text("Buy snippets with coins")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(Art.paper)
                        }
                        Spacer()
                        Image(systemName: showSnippetShop ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 23))
                            .foregroundStyle(Art.gold)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressGameStyle())

                if showSnippetShop {
                    Text("Coins buy snippets. Snippets unlock cosmetics. XP only increases your rank—it's never spent here.")
                        .font(.system(size: 12))
                        .foregroundStyle(Art.faded)
                    ForEach(SnippetPack.all) { pack in
                        Button {
                            if store.buySnippets(pack: pack) {
                                GameEffects.shared.success()
                                notice = "+\(pack.count) snippets saved to your wallet."
                            } else {
                                GameEffects.shared.mistake()
                                notice = "Not enough coins to purchase this pack."
                            }
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundStyle(Art.cyan)
                                Text("\(pack.count) SNIPPET\(pack.count == 1 ? "" : "S")")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                                Spacer()
                                CoinIcon(size: 22)
                                Text("\(pack.coins)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.gold)
                            }
                            .padding(12)
                            .background(Art.blueDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(store.coins >= pack.coins ? 1 : 0.50)
                        }
                        .buttonStyle(PressGameStyle())
                        .disabled(store.coins < pack.coins)
                    }
                }
            }
        }
    }
}
