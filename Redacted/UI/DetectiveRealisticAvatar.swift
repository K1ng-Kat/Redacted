import SwiftUI
import UIKit

/// A single square portrait for each saved skin tone and hair choice.
/// The supplied image is a 4-column (hair) by 5-row (skin) atlas.
/// Every frame uses the same pose and crop, so equipment stays attached.
enum DetectivePortraitLibrary {
    private static let atlas = UIImage(named: "DetectivePortraitAtlas")
    private static let portraits: [UIImage] = {
        guard let raw = atlas?.cgImage else { return [] }
        var result: [UIImage] = []
        for row in 0..<5 {
            for column in 0..<4 {
                let x0 = raw.width * column / 4
                let y0 = raw.height * row / 5
                let x1 = raw.width * (column + 1) / 4
                let y1 = raw.height * (row + 1) / 5
                guard let crop = raw.cropping(to: CGRect(x: x0, y: y0,
                                        width: x1 - x0, height: y1 - y0)) else { return [] }
                result.append(UIImage(cgImage: crop, scale: 1, orientation: .up))
            }
        }
        return result
    }()

    static func portrait(skin: DetectiveSkin, hair: DetectiveHair) -> UIImage? {
        guard let row = DetectiveSkin.allCases.firstIndex(of: skin),
              let column = DetectiveHair.allCases.firstIndex(of: hair) else { return nil }
        let index = row * 4 + column
        return portraits.indices.contains(index) ? portraits[index] : nil
    }
}

/// Cinematic character-card replacement. Reuses the existing saved wardrobe
/// IDs, appearance settings, and preview behavior; no new currency or unlocks.
struct DetectiveRealisticAvatar: View {
    let portrait: UIImage
    let theme: String
    let skin: DetectiveSkin
    let hair: DetectiveHair
    let loadout: [CosmeticSlot: String]
    let size: CGFloat

    private var accent: Color {
        DetectiveIdentity.colors[DetectiveIdentity.index(for: theme)]
    }

    var body: some View {
        ZStack {
            Image(uiImage: portrait)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()

            // Film-style grading, while retaining the photographic face,
            // textile texture, shadows and skin detail from the source.
            LinearGradient(colors: [
                accent.opacity(0.025), .clear, Art.ink.opacity(0.20)
            ], startPoint: .top, endPoint: .bottom)

            DetectiveRealisticEquipment(loadout: loadout, size: size)
                .frame(width: size, height: size)

            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.46)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: size * 0.22)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .strokeBorder(accent.opacity(0.52), lineWidth: max(1, size / 130))
        }
        .accessibilityLabel("Realistic detective portrait, \(skin.label) skin, \(hair.label) hair, with selected equipment")
    }
}

/// Equipment has no hit targets: selecting, buying, equipping and previewing
/// still happen in the existing Style Lab. Coordinates are normalized to 300.
private struct DetectiveRealisticEquipment: View {
    let loadout: [CosmeticSlot: String]
    let size: CGFloat

    private var outfit: String { loadout[.coat] ?? "" }
    private var coatColor: Color? {
        switch outfit {
        case "coat_navy": Color(red: 0.20, green: 0.45, blue: 0.78)
        case "coat_crimson": Color(red: 0.75, green: 0.20, blue: 0.32)
        case "coat_ghost": Color(red: 0.82, green: 0.86, blue: 0.94)
        case "coat_royal": Color(red: 0.40, green: 0.27, blue: 0.73)
        case "coat_sand": Color(red: 0.77, green: 0.64, blue: 0.39)
        case "coat_evergreen": Color(red: 0.15, green: 0.60, blue: 0.40)
        case "coat_noir": Color(red: 0.25, green: 0.33, blue: 0.43)
        case "coat_arctic": Color(red: 0.71, green: 0.84, blue: 0.91)
        case "coat_sunset": Color(red: 0.91, green: 0.42, blue: 0.24)
        case "coat_cipher": Color(red: 0.32, green: 0.34, blue: 0.72)
        default: nil
        }
    }

    var body: some View {
        Canvas(opaque: false) { context, canvas in
            var g = context
            g.scaleBy(x: canvas.width / 300, y: canvas.height / 300)
            coat(in: &g)
            badge(in: &g)
            glasses(in: &g)
            headwear(in: &g)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func shape(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      radius: CGFloat = 0) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h),
             cornerRadius: radius)
    }

    private func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
    }

    private func coat(in g: inout GraphicsContext) {
        guard let tint = coatColor else { return }
        // Restrict garment coloring to the visible jacket panels, keeping
        // hair, hands, face and the shirt unchanged. Low-opacity glazing
        // preserves the photo's stitches, fabric and specular highlights.
        let left = shape([
            CGPoint(x: 89, y: 99), CGPoint(x: 113, y: 112),
            CGPoint(x: 131, y: 125), CGPoint(x: 134, y: 262),
            CGPoint(x: 75, y: 272), CGPoint(x: 70, y: 144)
        ])
        let right = shape([
            CGPoint(x: 211, y: 99), CGPoint(x: 187, y: 112),
            CGPoint(x: 169, y: 125), CGPoint(x: 166, y: 262),
            CGPoint(x: 225, y: 272), CGPoint(x: 230, y: 144)
        ])
        let leftArm = shape([
            CGPoint(x: 87, y: 105), CGPoint(x: 70, y: 126),
            CGPoint(x: 61, y: 257), CGPoint(x: 91, y: 264),
            CGPoint(x: 100, y: 159)
        ])
        let rightArm = shape([
            CGPoint(x: 213, y: 105), CGPoint(x: 230, y: 126),
            CGPoint(x: 239, y: 257), CGPoint(x: 209, y: 264),
            CGPoint(x: 200, y: 159)
        ])
        for piece in [left, right, leftArm, rightArm] {
            g.fill(piece, with: .color(tint.opacity(0.36)))
        }
        // Subtle tailoring rather than flat color patches.
        g.stroke(shape([CGPoint(x: 113, y: 112), CGPoint(x: 132, y: 128),
                         CGPoint(x: 140, y: 167)]),
                 with: .color(tint.opacity(0.42)), lineWidth: 1)
        g.stroke(shape([CGPoint(x: 187, y: 112), CGPoint(x: 168, y: 128),
                         CGPoint(x: 160, y: 167)]),
                 with: .color(tint.opacity(0.42)), lineWidth: 1)
    }

    private func badge(in g: inout GraphicsContext) {
        guard let item = loadout[.badge] else { return }
        let gold = Color(red: 0.88, green: 0.70, blue: 0.37)
        let steel = Color(red: 0.77, green: 0.86, blue: 0.95)
        let metal: Color
        if item.contains("bronze") { metal = Color(red: 0.73, green: 0.45, blue: 0.30) }
        else if item.contains("silver") || item.contains("diamond") || item.contains("onyx") {
            metal = steel
        } else if item.contains("case") || item.contains("neon") { metal = Art.cyan }
        else { metal = gold }

        let insignia = shape([
            CGPoint(x: 185, y: 129), CGPoint(x: 193, y: 133),
            CGPoint(x: 191, y: 146), CGPoint(x: 185, y: 151),
            CGPoint(x: 179, y: 146), CGPoint(x: 177, y: 133)
        ])
        g.fill(insignia, with: .linearGradient(
            Gradient(colors: [.white.opacity(0.96), metal, metal.opacity(0.62)]),
            startPoint: CGPoint(x: 178, y: 129), endPoint: CGPoint(x: 193, y: 152)))
        g.stroke(insignia, with: .color(.black.opacity(0.82)), lineWidth: 1.4)
        g.fill(oval(183, 136, 4, 4), with: .color(.black.opacity(0.56)))
        g.fill(oval(182, 133, 2, 2), with: .color(.white.opacity(0.93)))
    }

    private func glasses(in g: inout GraphicsContext) {
        guard let item = loadout[.eyewear] else { return }
        let night = item == "glasses_visor" || item == "glasses_night" ||
                    item == "glasses_holo" || item == "glasses_ice"
        let lensTint: Color = {
            switch item {
            case "glasses_amber": .orange
            case "glasses_ruby": .red
            case "glasses_holo", "glasses_ice": Art.cyan
            default: Color(red: 0.14, green: 0.19, blue: 0.24)
            }
        }()
        let frame: Color = item == "glasses_clear" ? .white :
                           item == "glasses_monocle" ? Art.gold : .black
        if night {
            let visor = rect(119, 41, 62, 22, radius: 7)
            g.fill(visor, with: .color(lensTint.opacity(0.56)))
            g.stroke(visor, with: .color(frame.opacity(0.92)), lineWidth: 3.2)
            g.stroke(rect(122, 44, 55, 3, radius: 1),
                     with: .color(.white.opacity(0.42)), lineWidth: 1)
        } else if item == "glasses_monocle" {
            g.stroke(oval(156, 41, 26, 22), with: .color(frame), lineWidth: 2.7)
            g.stroke(shape([CGPoint(x: 180, y: 55), CGPoint(x: 187, y: 77),
                            CGPoint(x: 183, y: 98)]),
                     with: .color(Art.gold.opacity(0.75)), lineWidth: 1)
        } else {
            for x: CGFloat in [120, 155] {
                let lens = rect(x, 42, 27, 20, radius: item == "glasses_round" ? 10 : 5)
                g.fill(lens, with: .color(lensTint.opacity(
                    item == "glasses_clear" ? 0.06 : 0.26)))
                g.stroke(lens, with: .color(frame.opacity(0.86)), lineWidth: 2.7)
                g.stroke(rect(x + 3, 44, 13, 2, radius: 1),
                         with: .color(.white.opacity(0.25)), lineWidth: 0.7)
            }
            g.stroke(shape([CGPoint(x: 147, y: 51), CGPoint(x: 155, y: 51)]),
                     with: .color(frame), lineWidth: 2.5)
        }
    }

    private func headwear(in g: inout GraphicsContext) {
        guard let item = loadout[.headwear] else { return }
        let dark = Color(red: 0.085, green: 0.12, blue: 0.16)
        let material: Color
        switch item {
        case "hat_beret": material = Color(red: 0.41, green: 0.12, blue: 0.18)
        case "hat_cap": material = Color(red: 0.16, green: 0.29, blue: 0.36)
        case "hat_newsboy": material = Color(red: 0.41, green: 0.32, blue: 0.22)
        case "hat_winter": material = Color(red: 0.69, green: 0.74, blue: 0.82)
        case "hat_visor": material = Color(red: 0.12, green: 0.40, blue: 0.38)
        case "hat_director", "hat_pilot": material = Color(red: 0.19, green: 0.25, blue: 0.34)
        default: material = dark
        }

        let crown: Path
        switch item {
        case "hat_fedora":
            crown = shape([CGPoint(x: 125, y: 27), CGPoint(x: 128, y: 3),
                           CGPoint(x: 164, y: 0), CGPoint(x: 176, y: 27)])
        case "hat_hood":
            crown = shape([CGPoint(x: 113, y: 48), CGPoint(x: 117, y: 9),
                           CGPoint(x: 134, y: 0), CGPoint(x: 165, y: 0),
                           CGPoint(x: 184, y: 12), CGPoint(x: 186, y: 48),
                           CGPoint(x: 175, y: 20), CGPoint(x: 125, y: 20)])
        default:
            crown = shape([CGPoint(x: 121, y: 30), CGPoint(x: 124, y: 12),
                           CGPoint(x: 135, y: 4), CGPoint(x: 164, y: 4),
                           CGPoint(x: 176, y: 15), CGPoint(x: 179, y: 30)])
        }
        g.fill(crown, with: .linearGradient(
            Gradient(colors: [material.opacity(0.92), material,
                              dark.opacity(0.98)]),
            startPoint: CGPoint(x: 121, y: 3), endPoint: CGPoint(x: 180, y: 34)))
        g.stroke(crown, with: .color(.black.opacity(0.55)), lineWidth: 1.9)

        if item == "hat_fedora" {
            g.fill(rect(110, 28, 81, 5, radius: 2),
                   with: .color(dark.opacity(0.95)))
            g.fill(rect(128, 22, 47, 5), with: .color(Art.gold.opacity(0.52)))
        } else if item != "hat_hood" {
            let brim = shape([CGPoint(x: 118, y: 28), CGPoint(x: 181, y: 28),
                              CGPoint(x: 187, y: 34), CGPoint(x: 117, y: 36)])
            g.fill(brim, with: .color(material.opacity(0.97)))
            g.stroke(brim, with: .color(.black.opacity(0.60)), lineWidth: 1)
            g.stroke(rect(128, 25, 43, 1.5),
                     with: .color(.white.opacity(0.13)), lineWidth: 0.7)
        }
    }
}
