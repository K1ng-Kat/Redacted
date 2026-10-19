import SwiftUI

/// Original seven-facet REDACTED prism.
/// Geometry and colors are independently designed rather than traced from
/// an existing brand's symmetrical hexagonal logo.
struct CrystalIcon: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            CrystalFacet(points: [
                CGPoint(x: 0.50, y: 0.02), CGPoint(x: 0.84, y: 0.16),
                CGPoint(x: 0.97, y: 0.43), CGPoint(x: 0.69, y: 0.91),
                CGPoint(x: 0.38, y: 0.98), CGPoint(x: 0.04, y: 0.55),
                CGPoint(x: 0.19, y: 0.21)
            ])
            .fill(Color(red: 0.30, green: 0.16, blue: 0.66))

            CrystalFacet(points: [
                CGPoint(x: 0.19, y: 0.21), CGPoint(x: 0.50, y: 0.02),
                CGPoint(x: 0.53, y: 0.40), CGPoint(x: 0.35, y: 0.61),
                CGPoint(x: 0.04, y: 0.55)
            ])
            .fill(Color(red: 0.84, green: 0.67, blue: 1.0))

            CrystalFacet(points: [
                CGPoint(x: 0.50, y: 0.02), CGPoint(x: 0.84, y: 0.16),
                CGPoint(x: 0.97, y: 0.43), CGPoint(x: 0.53, y: 0.40)
            ])
            .fill(Color(red: 0.66, green: 0.45, blue: 0.94))

            CrystalFacet(points: [
                CGPoint(x: 0.04, y: 0.55), CGPoint(x: 0.35, y: 0.61),
                CGPoint(x: 0.38, y: 0.98)
            ])
            .fill(Color(red: 0.41, green: 0.25, blue: 0.83))

            CrystalFacet(points: [
                CGPoint(x: 0.35, y: 0.61), CGPoint(x: 0.53, y: 0.40),
                CGPoint(x: 0.69, y: 0.91), CGPoint(x: 0.38, y: 0.98)
            ])
            .fill(Color(red: 0.91, green: 0.77, blue: 1.0))

            CrystalFacet(points: [
                CGPoint(x: 0.53, y: 0.40), CGPoint(x: 0.97, y: 0.43),
                CGPoint(x: 0.69, y: 0.91)
            ])
            .fill(Color(red: 0.52, green: 0.25, blue: 0.82))

            CrystalFacet(points: [
                CGPoint(x: 0.53, y: 0.40), CGPoint(x: 0.66, y: 0.34),
                CGPoint(x: 0.69, y: 0.65)
            ])
            .fill(Color.white.opacity(0.76))
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 0.60, green: 0.37, blue: 0.93).opacity(0.38),
                radius: size * 0.11, y: size * 0.06)
        .accessibilityHidden(true)
    }
}

private struct CrystalFacet: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: rect.minX + first.x * rect.width,
                              y: rect.minY + first.y * rect.height))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: rect.minX + point.x * rect.width,
                                    y: rect.minY + point.y * rect.height))
        }
        path.closeSubpath()
        return path
    }
}
