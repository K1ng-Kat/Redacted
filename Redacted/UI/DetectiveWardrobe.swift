import SwiftUI

enum CosmeticSlot: String, CaseIterable, Identifiable, Codable {
    case headwear, eyewear, badge, coat
    var id: String { rawValue }
    var label: String {
        switch self {
        case .headwear: "HEADWEAR"
        case .eyewear: "EYEWEAR"
        case .badge: "BADGE"
        case .coat: "OUTFIT"
        }
    }
}

struct DetectiveCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let slot: CosmeticSlot
    let symbol: String
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
    ]
    static func item(_ id: String?) -> DetectiveCosmetic? { all.first { $0.id == id } }
}

/// Collectible items are drawn on top of the existing character portrait.
struct DetectiveCharacter: View {
    @ObservedObject var store: CampaignStore
    var size: CGFloat = 140
    @AppStorage("redacted.profile.theme") private var theme = "midnight"

    private var outfit: DetectiveCosmetic? { CosmeticCatalog.item(store.equippedCosmetic(in: .coat)) }

    var body: some View {
        ZStack {
            DetectivePortrait(theme: theme, size: size)
            if let outfit {
                Image(systemName: outfit.symbol)
                    .font(.system(size: size * 0.25, weight: .black))
                    .foregroundStyle(outfit.tint)
                    .padding(size * 0.045)
                    .background(Art.blueDeep.opacity(0.8))
                    .clipShape(Circle())
                    .offset(x: -size * 0.26, y: size * 0.26)
            }
            if let hat = CosmeticCatalog.item(store.equippedCosmetic(in: .headwear)) {
                Image(systemName: hat.symbol)
                    .font(.system(size: size * 0.31, weight: .black))
                    .foregroundStyle(hat.tint)
                    .shadow(color: Art.ink, radius: 3)
                    .offset(y: -size * 0.32)
            }
            if let glasses = CosmeticCatalog.item(store.equippedCosmetic(in: .eyewear)) {
                Image(systemName: glasses.symbol)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(glasses.tint)
                    .shadow(color: Art.ink, radius: 2)
                    .offset(y: -size * 0.06)
            }
            if let badge = CosmeticCatalog.item(store.equippedCosmetic(in: .badge)) {
                Image(systemName: badge.symbol)
                    .font(.system(size: size * 0.20, weight: .black))
                    .foregroundStyle(badge.tint)
                    .offset(x: size * 0.28, y: size * 0.32)
                    .shadow(color: Art.ink, radius: 3)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Your customized detective")
    }
}

struct DetectiveWardrobeView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void
    @State private var selectedSlot: CosmeticSlot = .headwear
    @State private var pendingPurchase: DetectiveCosmetic?
    @State private var purchaseWithCrystals = false
    @State private var note: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                ScreenHeader(title: "MY DETECTIVE", subtitle: "STYLE LAB & SNIPPET SHOP", back: back)
                GameCard(accent: Art.cyan) {
                    HStack(spacing: 16) {
                        DetectiveCharacter(store: store, size: 115)
                        VStack(alignment: .leading, spacing: 9) {
                            GameKicker(text: "YOUR LOADOUT", color: Art.gold)
                            Text("RANK \(store.accountLevel)")
                                .font(.system(size: 21, weight: .black, design: .rounded))
                                .foregroundStyle(Art.paper)
                            HStack(spacing: 8) {
                                CoinIcon(size: 23)
                                Text("\(store.coins)")
                                CrystalIcon(size: 23)
                                Text("\(store.crystals)")
                            }
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(Art.paper)
                            Text("\(store.snippets) saved snippets")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(Art.cyan)
                        }
                        Spacer(minLength: 0)
                    }
                }

                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 12) {
                        GameKicker(text: "BUY SNIPPETS WITH COINS", color: Art.gold)
                        Text("Save snippets to permanently unlock detective cosmetics. Or spend crystals to unlock a rank-eligible item immediately.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Art.paper)
                        ForEach(SnippetPack.all) { pack in
                            Button {
                                if store.buySnippets(pack: pack) {
                                    GameEffects.shared.success()
                                    note = "Added \(pack.count) snippets to your collection."
                                } else {
                                    GameEffects.shared.mistake()
                                    note = "Not enough coins."
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .foregroundStyle(Art.cyan)
                                    Text("\(pack.count) SNIPPET\(pack.count == 1 ? "" : "S")")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(Art.paper)
                                    Spacer()
                                    CoinIcon(size: 23)
                                    Text("\(pack.coins)")
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundStyle(Art.gold)
                                }
                                .padding(11)
                                .background(Art.blueDeep)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PressGameStyle())
                            .disabled(store.coins < pack.coins)
                        }
                    }
                }

                HStack(spacing: 7) {
                    ForEach(CosmeticSlot.allCases) { slot in
                        Button {
                            selectedSlot = slot
                            GameEffects.shared.tap()
                        } label: {
                            Text(slot.label)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(selectedSlot == slot ? Art.ink : Art.paper)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedSlot == slot ? Art.gold : Art.blueDeep)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(PressGameStyle())
                    }
                }
                if store.equippedCosmetic(in: selectedSlot) != nil {
                    GameButton(title: "REMOVE \(selectedSlot.label)", icon: "xmark.circle.fill",
                               color: Art.blueLight, bottom: Art.blueDeep) {
                        store.unequipCosmetic(slot: selectedSlot)
                    }
                }

                ForEach(CosmeticCatalog.all.filter { $0.slot == selectedSlot }) { item in
                    let owned = store.ownedCosmetics.contains(item.id)
                    let available = store.accountLevel >= item.requiredRank
                    let equipped = store.equippedCosmetic(in: item.slot) == item.id
                    GameCard(accent: owned ? Art.mint : available ? Art.gold : Art.edge) {
                        HStack(spacing: 12) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(item.tint)
                                .frame(width: 55, height: 55)
                                .background(Art.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name.uppercased())
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                                GameKicker(text: "UNLOCK AT RANK \(item.requiredRank)",
                                           color: available ? Art.mint : Art.faded)
                                if available && !owned {
                                    Text("\(item.snippetPrice) snippets or \(item.crystalPrice) crystals")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Art.gold)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        if owned {
                            GameButton(title: equipped ? "EQUIPPED" : "EQUIP", icon: "checkmark",
                                       inactive: equipped) {
                                store.equipCosmetic(item)
                            }
                        } else if available {
                            HStack(spacing: 8) {
                                GameButton(title: "\(item.snippetPrice) SNIPPETS",
                                           icon: "square.stack.3d.up.fill",
                                           color: Art.blueLight, bottom: Art.blueDeep,
                                           inactive: store.snippets < item.snippetPrice) {
                                    pendingPurchase = item
                                    purchaseWithCrystals = false
                                }
                                GameButton(title: "\(item.crystalPrice) GEMS",
                                           icon: "sparkles",
                                           inactive: store.crystals < item.crystalPrice) {
                                    pendingPurchase = item
                                    purchaseWithCrystals = true
                                }
                            }
                        } else {
                            Text("Keep solving cases to reach Rank \(item.requiredRank).")
                                .font(.system(size: 12))
                                .foregroundStyle(Art.faded)
                        }
                    }
                }
                if let note {
                    Text(note)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Art.cyan)
                }
            }
            .frame(maxWidth: 580)
            .padding(17)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .confirmationDialog("UNLOCK COSMETIC?", isPresented: Binding(
            get: { pendingPurchase != nil },
            set: { if !$0 { pendingPurchase = nil } }
        ), titleVisibility: .visible) {
            if let item = pendingPurchase {
                Button("Unlock for \(purchaseWithCrystals ? item.crystalPrice : item.snippetPrice) \(purchaseWithCrystals ? "crystals" : "snippets")") {
                    if store.unlockCosmetic(item, crystals: purchaseWithCrystals) {
                        GameEffects.shared.success()
                        note = "\(item.name) unlocked and equipped!"
                    }
                    pendingPurchase = nil
                }
            }
            Button("Cancel", role: .cancel) { pendingPurchase = nil }
        } message: {
            Text("This permanently unlocks the item. The cost is deducted once.")
        }
    }
}
