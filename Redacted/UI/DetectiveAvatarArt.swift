import SwiftUI

/// The character is one 300x300 illustration. Every accessory uses the SAME
/// normalized face/body coordinates, at every preview size. No floating
/// SF Symbols or view offsets, and no external art or asset licensing.
enum DetectiveSkin: String, CaseIterable, Identifiable, Codable {
    case porcelain, peach, bronze, umber, deep
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .porcelain: Color(red: 0.98, green: 0.81, blue: 0.69)
        case .peach: Color(red: 0.91, green: 0.64, blue: 0.47)
        case .bronze: Color(red: 0.71, green: 0.44, blue: 0.30)
        case .umber: Color(red: 0.48, green: 0.29, blue: 0.21)
        case .deep: Color(red: 0.30, green: 0.18, blue: 0.15)
        }
    }
}

enum DetectiveHair: String, CaseIterable, Identifiable, Codable {
    case classic, textured, swept, cropped
    var id: String { rawValue }
    var label: String {
        switch self {
        case .classic: "Classic"
        case .textured: "Textured"
        case .swept: "Side Sweep"
        case .cropped: "Cropped"
        }
    }
}

struct DetectiveAvatarArt: View {
    let theme: String
    let skin: DetectiveSkin
    let hair: DetectiveHair
    let loadout: [CosmeticSlot: String]
    var size: CGFloat = 240
    var showStage: Bool = true

    private var accent: Color {
        DetectiveIdentity.colors[DetectiveIdentity.index(for: theme)]
    }
    private var outfit: String { loadout[.coat] ?? "" }

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, canvas in
            var g = context
            g.scaleBy(x: canvas.width / 300, y: canvas.height / 300)
            draw(in: &g)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.14))
        .overlay(RoundedRectangle(cornerRadius: size * 0.14)
            .stroke(accent.opacity(0.42), lineWidth: max(1, size / 110)))
        .accessibilityLabel("Illustrated detective, wearing selected cosmetics")
    }

    private func polygon(_ xy: [CGFloat]) -> Path {
        var p = Path()
        guard xy.count >= 6 else { return p }
        p.move(to: CGPoint(x: xy[0], y: xy[1]))
        var i = 2
        while i + 1 < xy.count {
            p.addLine(to: CGPoint(x: xy[i], y: xy[i + 1]))
            i += 2
        }
        p.closeSubpath()
        return p
    }

    private func circle(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      _ radius: CGFloat = 0) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h),
             cornerRadius: radius)
    }

    private func strokeLine(_ coords: [CGFloat]) -> Path {
        var p = Path()
        guard coords.count >= 4 else { return p }
        p.move(to: CGPoint(x: coords[0], y: coords[1]))
        var i = 2
        while i + 1 < coords.count {
            p.addLine(to: CGPoint(x: coords[i], y: coords[i + 1]))
            i += 2
        }
        return p
    }

    private func paint(_ g: inout GraphicsContext, _ path: Path,
                       _ color: Color, border: Color? = nil, width: CGFloat = 3) {
        g.fill(path, with: .color(color))
        if let border {
            g.stroke(path, with: .color(border), lineWidth: width)
        }
    }

    private func line(_ g: inout GraphicsContext, _ coords: [CGFloat],
                      _ color: Color, width: CGFloat = 3) {
        g.stroke(strokeLine(coords), with: .color(color),
                 style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func draw(in g: inout GraphicsContext) {
        let outline = Color(red: 0.055, green: 0.09, blue: 0.16)
        let ink = Color(red: 0.09, green: 0.15, blue: 0.25)
        let highlight = accent
        let skinColor = skin.color
        let skinShade = skinColor.opacity(0.85)
        let baseCoat: Color
        let trim: Color
        switch outfit {
        case "coat_navy":
            baseCoat = Color(red: 0.14, green: 0.39, blue: 0.65)
            trim = Color(red: 0.43, green: 0.81, blue: 0.94)
        case "coat_crimson":
            baseCoat = Color(red: 0.70, green: 0.21, blue: 0.33)
            trim = Color(red: 1.0, green: 0.70, blue: 0.48)
        case "coat_ghost":
            baseCoat = Color(red: 0.76, green: 0.81, blue: 0.90)
            trim = Color(red: 0.35, green: 0.56, blue: 0.75)
        case "coat_royal":
            baseCoat = Color(red: 0.26, green: 0.19, blue: 0.56)
            trim = Color(red: 0.95, green: 0.76, blue: 0.40)
        default:
            baseCoat = Color(red: 0.13, green: 0.24, blue: 0.39)
            trim = highlight
        }

        // A single inset portrait stage, consistent across the Wardrobe, Profile,
        // case results and cosmetic item thumbnails.
        paint(&g, rect(0, 0, 300, 300, 34), Color(red: 0.055, green: 0.11, blue: 0.20))
        if showStage {
            paint(&g, circle(34, 14, 232, 242), highlight.opacity(0.13))
            paint(&g, circle(53, 32, 195, 195), highlight.opacity(0.10))
            line(&g, [25, 248, 52, 248], highlight.opacity(0.55), width: 3)
            line(&g, [248, 248, 275, 248], highlight.opacity(0.55), width: 3)
            line(&g, [24, 35, 24, 56], highlight.opacity(0.6), width: 3)
            line(&g, [24, 35, 45, 35], highlight.opacity(0.6), width: 3)
        }

        // Coat and shoulders BEFORE head so the neckline aligns perfectly.
        paint(&g, polygon([14,300, 19,260, 45,223, 106,202, 150,214,
                           194,202, 255,223, 281,260, 286,300]),
              baseCoat, border: outline, width: 7)
        paint(&g, polygon([105,204, 150,220, 194,204, 179,298, 120,298]),
              Color(red: 0.19, green: 0.27, blue: 0.39), border: outline, width: 4)
        paint(&g, polygon([133,205, 150,226, 167,205, 159,297, 142,297]),
              Color(red: 0.93, green: 0.91, blue: 0.84))
        paint(&g, polygon([146,230, 154,230, 160,277, 150,289, 141,277]),
              outfit == "coat_royal" ? trim : Color(red: 0.38, green: 0.70, blue: 0.82),
              border: outline, width: 2)
        // Notched lapels and central seam are physical garment components.
        paint(&g, polygon([105,204, 139,229, 124,261, 144,298, 72,298,
                           65,237, 97,228]),
              baseCoat.opacity(0.90), border: outline, width: 3.5)
        paint(&g, polygon([195,204, 161,229, 176,261, 156,298, 228,298,
                           235,237, 203,228]),
              baseCoat.opacity(0.90), border: outline, width: 3.5)
        line(&g, [105,205, 130,231, 116,251], trim.opacity(0.95), width: 4)
        line(&g, [195,205, 170,231, 184,251], trim.opacity(0.95), width: 4)
        line(&g, [150,285, 150,299], outline, width: 3)
        paint(&g, circle(162,274,7,7), trim)
        // Sleeve blocks follow shoulder contour.
        line(&g, [46,233, 39,292], outline.opacity(0.48), width: 4)
        line(&g, [253,233, 261,292], outline.opacity(0.48), width: 4)
        if outfit == "coat_ghost" {
            line(&g, [70,277,106,277], trim, width: 5)
            line(&g, [195,277,232,277], trim, width: 5)
        } else if outfit == "coat_royal" {
            line(&g, [58,286,105,286], trim, width: 4)
            line(&g, [195,286,242,286], trim, width: 4)
            paint(&g, circle(149,248,5,5), trim)
        }

        // Neck and ears.
        paint(&g, rect(131,165,38,53,13), skinShade, border: outline, width: 3)
        paint(&g, circle(91,125,23,31), skinColor, border: outline)
        paint(&g, circle(186,125,23,31), skinColor, border: outline)

        // Face uses one shared head geometry across all cosmetic styles.
        paint(&g, circle(99,65,102,127), skinColor, border: outline, width: 5)
        paint(&g, circle(108,149,17,8), Color.white.opacity(0.07))
        paint(&g, circle(175,149,17,8), Color.white.opacity(0.07))
        line(&g, [145,133, 140,157, 149,161], outline.opacity(0.55), width: 2.2)
        line(&g, [137,177, 150,181, 164,176], outline.opacity(0.76), width: 2.8)

        // Eyes / brows drawn at a stable baseline.
        line(&g, [119,121, 139,118], outline, width: 4)
        line(&g, [163,118, 182,121], outline, width: 4)
        paint(&g, circle(125,132,7,8), outline)
        paint(&g, circle(170,132,7,8), outline)
        paint(&g, circle(128,133,2.5,2.5), Color.white)
        paint(&g, circle(173,133,2.5,2.5), Color.white)

        // Hair is drawn relative to the skull, NOT the outer view.
        let hairDark = Color(red: 0.13, green: 0.11, blue: 0.17)
        switch hair {
        case .classic:
            paint(&g, polygon([98,115, 96,89, 108,64, 135,52, 170,53,
                               197,74, 205,111, 188,96, 165,78, 144,88,
                               120,82, 110,106]),
                  hairDark, border: outline, width: 3)
        case .textured:
            paint(&g, polygon([96,115, 91,84, 103,78, 100,59, 122,67,
                               135,47, 151,63, 168,44, 180,62, 198,58,
                               203,80, 196,112, 184,91, 165,102, 153,86,
                               132,105, 115,91, 109,116]),
                  hairDark, border: outline, width: 3)
            line(&g, [119,80,130,73,140,78], highlight.opacity(0.28), width: 3)
        case .swept:
            paint(&g, polygon([96,109, 91,83, 113,59, 150,50, 197,72,
                               205,110, 186,105, 176,94, 149,92, 125,103,
                               108,122]),
                  hairDark, border: outline, width: 3)
            line(&g, [110,87, 158,66, 187,80], highlight.opacity(0.18), width: 3)
        case .cropped:
            paint(&g, polygon([96,106, 98,79, 117,61, 149,56, 181,61,
                               203,80, 204,107, 187,94, 165,87,
                               134,88, 110,99]),
                  hairDark, border: outline, width: 3)
        }

        // EYEWEAR: anchored directly to x=115–185, y=137, at the eyes.
        switch loadout[.eyewear] {
        case "glasses_round":
            g.stroke(circle(110,120,38,36), with: .color(outline), lineWidth: 5)
            g.stroke(circle(152,120,38,36), with: .color(outline), lineWidth: 5)
            line(&g, [148,135,153,135], outline, width: 4)
            line(&g, [110,131,101,129], outline, width: 4)
            line(&g, [190,131,199,129], outline, width: 4)
        case "glasses_visor":
            paint(&g, polygon([106,121, 193,121, 191,150, 150,154, 110,150]),
                  Color(red: 0.12, green: 0.39, blue: 0.48), border: outline, width: 4)
            line(&g, [115,128, 185,128], Color(red: 0.60, green: 0.97, blue: 0.97), width: 3)
        case "glasses_night":
            paint(&g, rect(107,120,85,35,11),
                  Color(red: 0.08, green: 0.13, blue: 0.20), border: highlight, width: 4)
            line(&g, [115,126,138,126], Color(red: 0.46, green: 0.98, blue: 0.76), width: 3)
            line(&g, [162,126,184,126], Color(red: 0.46, green: 0.98, blue: 0.76), width: 3)
        default: break
        }

        // BADGE: physically located on the right lapel.
        let badgeX: CGFloat = 206
        let badgeY: CGFloat = 256
        switch loadout[.badge] {
        case "badge_bronze":
            paint(&g, polygon([badgeX,badgeY-17, badgeX+12,badgeY-9,
                               badgeX+10,badgeY+12, badgeX,badgeY+19,
                               badgeX-10,badgeY+12, badgeX-12,badgeY-9]),
                  Color(red: 0.77, green: 0.43, blue: 0.21), border: outline, width: 3)
        case "badge_silver":
            paint(&g, star(cx: badgeX, cy: badgeY, radius: 18),
                  Color(red: 0.82, green: 0.89, blue: 0.98), border: outline, width: 3)
        case "badge_gold":
            paint(&g, circle(badgeX-17, badgeY-17,34,34),
                  Color(red: 0.95, green: 0.70, blue: 0.24), border: outline, width: 3)
            paint(&g, star(cx: badgeX, cy: badgeY, radius: 12),
                  Color(red: 1.0, green: 0.94, blue: 0.65))
        case "badge_director":
            paint(&g, polygon([badgeX-19,badgeY-10, badgeX-10,badgeY-1,
                               badgeX,badgeY-16, badgeX+10,badgeY-1,
                               badgeX+19,badgeY-10, badgeX+15,badgeY+14,
                               badgeX-15,badgeY+14]),
                  Color(red: 0.99, green: 0.81, blue: 0.38), border: outline, width: 3)
            paint(&g, circle(badgeX-3,badgeY+1,6,6), Color.white)
        default: break
        }

        // HEADWEAR: cap/beret/fedora/crown ALL share the top-of-scalp anchor
        // y ~= 72, and never float above the character.
        switch loadout[.headwear] {
        case "hat_cap":
            paint(&g, polygon([97,89, 100,71, 120,58, 165,55, 193,68, 200,90]),
                  Color(red: 0.18, green: 0.45, blue: 0.59), border: outline, width: 4)
            paint(&g, polygon([101,90, 201,89, 213,98, 168,102, 105,99]),
                  Color(red: 0.11, green: 0.31, blue: 0.43), border: outline, width: 3)
            line(&g, [142,70,165,70], trim, width: 3)
        case "hat_beret":
            paint(&g, circle(94,53,112,42),
                  Color(red: 0.58, green: 0.16, blue: 0.26), border: outline, width: 4)
            paint(&g, rect(106,83,92,12,5),
                  Color(red: 0.32, green: 0.11, blue: 0.22), border: outline, width: 2)
            line(&g, [148,52,154,42], outline, width: 4)
        case "hat_fedora":
            paint(&g, polygon([106,87, 111,48, 138,36, 180,43, 189,87]),
                  Color(red: 0.10, green: 0.13, blue: 0.20), border: outline, width: 4)
            paint(&g, rect(103,74,88,12,3),
                  Color(red: 0.64, green: 0.48, blue: 0.25))
            paint(&g, polygon([77,87, 221,87, 201,101, 103,101]),
                  Color(red: 0.12, green: 0.16, blue: 0.24), border: outline, width: 3)
        case "hat_director":
            paint(&g, polygon([95,89, 100,53, 112,42, 135,54, 151,36,
                               169,54, 187,42, 201,54, 205,90]),
                  Color(red: 0.17, green: 0.23, blue: 0.38), border: outline, width: 4)
            paint(&g, rect(98,81,105,14,6), Color(red: 0.94, green: 0.75, blue: 0.37))
            paint(&g, star(cx: 151, cy: 64, radius: 12), Color.white)
        default: break
        }

        if showStage {
            // Foreground lip hides torso at the bottom like a collectible card.
            paint(&g, rect(0,293,300,7), highlight.opacity(0.8))
        }
    }

    private func star(cx: CGFloat, cy: CGFloat, radius: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let theta = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i.isMultiple(of: 2) ? radius : radius * 0.46
            let point = CGPoint(x: cx + cos(theta) * r,
                                y: cy + sin(theta) * r)
            if i == 0 { p.move(to: point) }
            else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }
}
