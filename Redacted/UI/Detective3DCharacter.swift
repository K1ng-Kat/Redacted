import SceneKit
import SwiftUI
import UIKit

// Persisted style identifiers must remain stable across upgrades.
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

/// The detective is genuine 3D SceneKit geometry, not a photo, sticker,
/// sprite, flat portrait, or composited accessory image. All equipment is
/// attached to the same 3D model and moves with the head or torso.
/// A sculpted production mesh/USDZ with a full skeleton can replace this
/// procedural character in a later art pass without changing saved IDs.
struct Detective3DCharacter: UIViewRepresentable {
    let skin: DetectiveSkin
    let hair: DetectiveHair
    let equipment: [CosmeticSlot: String]
    let theme: String
    let size: CGFloat
    var portraitMode: Bool = false

    private var signature: String {
        ([skin.rawValue, hair.rawValue, theme, portraitMode ? "portrait" : "body"] +
         CosmeticSlot.allCases.map { equipment[$0] ?? "-" }).joined(separator: "|")
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = size >= 170 ? .multisampling4X : .multisampling2X
        view.preferredFramesPerSecond = size >= 170 ? 30 : 15
        view.rendersContinuously = size >= 170
        view.isPlaying = size >= 170
        view.scene = DetectiveModelFactory.make(skin: skin, hair: hair,
                                                equipment: equipment, theme: theme,
                                                closeup: portraitMode || size < 130,
                                                animated: size >= 170)
        view.pointOfView = view.scene?.rootNode.childNode(withName: "Detective camera", recursively: false)
        context.coordinator.signature = signature
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard context.coordinator.signature != signature else { return }
        context.coordinator.signature = signature
        view.scene = DetectiveModelFactory.make(skin: skin, hair: hair,
                                                equipment: equipment, theme: theme,
                                                closeup: portraitMode || size < 130,
                                                animated: size >= 170)
        view.pointOfView = view.scene?.rootNode.childNode(withName: "Detective camera", recursively: false)
    }

    final class Coordinator {
        var signature = ""
    }
}

private enum DetectiveModelFactory {
    private static let navy = UIColor(red: 0.14, green: 0.18, blue: 0.24, alpha: 1)
    private static let fabricDark = UIColor(red: 0.085, green: 0.11, blue: 0.16, alpha: 1)
    private static let shirt = UIColor(red: 0.64, green: 0.68, blue: 0.72, alpha: 1)
    private static let metal = UIColor(red: 0.78, green: 0.81, blue: 0.85, alpha: 1)
    private static let hairColor = UIColor(red: 0.105, green: 0.078, blue: 0.065, alpha: 1)

    static func make(skin: DetectiveSkin, hair: DetectiveHair,
                     equipment: [CosmeticSlot: String], theme: String,
                     closeup: Bool, animated: Bool) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        let color = UIColor(skin.color)
        let jacket = coatColor(equipment[.coat])
        let mannequin = SCNNode()
        scene.rootNode.addChildNode(mannequin)

        // Shoes and two independent anatomically proportioned legs.
        for side in [-1.0, 1.0] {
            let x = Float(side) * 0.115
            let boot = ellipsoid("Leather boot", fabricDark, x, 0.092, 0.044,
                                 0.082, 0.083, 0.164, roughness: 0.53)
            mannequin.addChildNode(boot)
            mannequin.addChildNode(ellipsoid("Lower trouser leg", navy,
                                            x, 0.420, -0.002,
                                            0.079, 0.30, 0.087))
            mannequin.addChildNode(ellipsoid("Knee fold", navy, x, 0.72, 0,
                                            0.083, 0.089, 0.088))
            mannequin.addChildNode(ellipsoid("Upper trouser leg", navy,
                                            x, 0.93, -0.006,
                                            0.103, 0.25, 0.105))
            mannequin.addChildNode(ellipsoid("Hand", color,
                                            Float(side) * 0.255, 0.885, 0.035,
                                            0.038, 0.075, 0.030, roughness: 0.82))
            // Jacket sleeves are real meshes, aligned to the arms.
            mannequin.addChildNode(segment("Upper jacket sleeve", jacket,
                           from: SCNVector3(Float(side) * 0.224, 1.560, 0),
                           to: SCNVector3(Float(side) * 0.276, 1.280, 0.004),
                           radius: 0.075))
            mannequin.addChildNode(segment("Lower jacket sleeve", jacket,
                           from: SCNVector3(Float(side) * 0.276, 1.278, 0.004),
                           to: SCNVector3(Float(side) * 0.257, 0.988, 0.028),
                           radius: 0.066))
            mannequin.addChildNode(ellipsoid("Jacket shoulder", jacket,
                                            Float(side) * 0.213, 1.559, 0,
                                            0.100, 0.086, 0.117))
        }

        // Pelvis, tailored three-dimensional coat, lapels, shirt and tie.
        mannequin.addChildNode(ellipsoid("Hip", navy, 0, 1.09, 0,
                                        0.193, 0.184, 0.108))
        mannequin.addChildNode(tailoredTorso(color: jacket))
        mannequin.addChildNode(box("Shirt placket", shirt,
                                  width: 0.112, height: 0.370, length: 0.015,
                                  x: 0, y: 1.420, z: 0.137,
                                  chamfer: 0.012))
        mannequin.addChildNode(box("Tie", fabricDark,
                                  width: 0.031, height: 0.253, length: 0.017,
                                  x: 0, y: 1.412, z: 0.150,
                                  chamfer: 0.005))
        for side in [-1.0, 1.0] {
            let lapel = box("Jacket lapel", jacket,
                            width: 0.067, height: 0.215, length: 0.024,
                            x: Float(side) * 0.092, y: 1.517, z: 0.144,
                            chamfer: 0.011)
            lapel.eulerAngles.z = Float(side) * -0.15
            mannequin.addChildNode(lapel)
            let pocket = box("Jacket pocket", jacket.withAlphaComponent(0.92),
                             width: 0.094, height: 0.065, length: 0.014,
                             x: Float(side) * 0.118, y: 1.280, z: 0.122,
                             chamfer: 0.005)
            mannequin.addChildNode(pocket)
        }
        mannequin.addChildNode(ellipsoid("Neck", color, 0, 1.690, 0,
                                        0.068, 0.080, 0.068, roughness: 0.83))

        // Pivot allows the entire head, hair, eyes and worn accessories to
        // animate together. Nothing is pasted onto a flat render.
        let head = SCNNode()
        head.name = "Head and equipment joint"
        head.position = SCNVector3(0, 1.700, 0)
        mannequin.addChildNode(head)
        makeFace(into: head, skin: color)
        makeHair(into: head, style: hair)
        makeEyewear(into: head, id: equipment[.eyewear])
        makeHeadwear(into: head, id: equipment[.headwear])
        makeBadge(into: mannequin, id: equipment[.badge])

        if animated {
            let a = SCNAction.rotateTo(x: 0.005, y: 0.038, z: 0,
                                       duration: 3.0, usesShortestUnitArc: true)
            let b = SCNAction.rotateTo(x: -0.005, y: -0.035, z: 0,
                                       duration: 3.2, usesShortestUnitArc: true)
            a.timingMode = .easeInEaseOut
            b.timingMode = .easeInEaseOut
            head.runAction(.repeatForever(.sequence([a, b])))
        }

        // Physically based studio lighting, soft contact shadow and camera.
        let platform = SCNNode(geometry: SCNCylinder(radius: 0.52, height: 0.037))
        platform.geometry?.firstMaterial = material(UIColor(red: 0.09, green: 0.13,
                                       blue: 0.20, alpha: 1), roughness: 0.62)
        platform.position.y = 0.015
        scene.rootNode.addChildNode(platform)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 360
        ambient.light?.color = UIColor(white: 0.78, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = light(at: SCNVector3(-1.8, 3.6, 3.0),
                        intensity: 1070, color: UIColor(white: 0.95, alpha: 1))
        key.light?.castsShadow = true
        key.light?.shadowRadius = 9
        key.light?.shadowSampleCount = 12
        scene.rootNode.addChildNode(key)
        scene.rootNode.addChildNode(light(at: SCNVector3(2.3, 2.6, -1.5),
                                        intensity: 690,
                                        color: UIColor(red: 0.47, green: 0.69,
                                                       blue: 0.88, alpha: 1)))

        let camera = SCNNode()
        camera.name = "Detective camera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = closeup ? 37 : 34
        camera.camera?.wantsHDR = true
        camera.camera?.exposureOffset = -0.08
        camera.position = closeup
            ? SCNVector3(0, 1.80, 1.08)
            : SCNVector3(0, 1.12, 3.55)
        camera.look(at: closeup ? SCNVector3(0, 1.78, 0)
                                : SCNVector3(0, 1.04, 0))
        camera.camera?.zNear = 0.025
        scene.rootNode.addChildNode(camera)
        return scene
    }

    private static func material(_ color: UIColor,
                                 roughness: CGFloat = 0.77,
                                 metalness: CGFloat = 0.01) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.roughness.contents = NSNumber(value: Double(roughness))
        m.metalness.contents = NSNumber(value: Double(metalness))
        return m
    }

    private static func ellipsoid(_ name: String, _ color: UIColor,
                                  _ x: Float, _ y: Float, _ z: Float,
                                  _ rx: CGFloat, _ ry: CGFloat, _ rz: CGFloat,
                                  roughness: CGFloat = 0.78) -> SCNNode {
        let geo = SCNSphere(radius: 1)
        geo.segmentCount = 26
        geo.firstMaterial = material(color, roughness: roughness)
        let node = SCNNode(geometry: geo)
        node.name = name
        node.position = SCNVector3(x, y, z)
        node.scale = SCNVector3(Float(rx), Float(ry), Float(rz))
        return node
    }

    private static func box(_ name: String, _ color: UIColor,
                            width: CGFloat, height: CGFloat, length: CGFloat,
                            x: Float, y: Float, z: Float,
                            chamfer: CGFloat = 0.0,
                            metalness: CGFloat = 0.015) -> SCNNode {
        let geo = SCNBox(width: width, height: height, length: length,
                         chamferRadius: chamfer)
        geo.firstMaterial = material(color, roughness: 0.70, metalness: metalness)
        let node = SCNNode(geometry: geo)
        node.name = name
        node.position = SCNVector3(x, y, z)
        return node
    }

    private static func segment(_ name: String, _ color: UIColor,
                                from a: SCNVector3, to b: SCNVector3,
                                radius: CGFloat) -> SCNNode {
        let delta = SCNVector3(b.x - a.x, b.y - a.y, b.z - a.z)
        let length = sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z)
        let geo = SCNCapsule(capRadius: radius, height: CGFloat(length) + radius)
        geo.radialSegmentCount = 16
        geo.firstMaterial = material(color)
        let node = SCNNode(geometry: geo)
        node.name = name
        node.position = SCNVector3((a.x + b.x) / 2,
                                   (a.y + b.y) / 2, (a.z + b.z) / 2)
        // Limbs bend outward in their shared X/Y plane.
        node.eulerAngles.z = atan2(-delta.x, delta.y)
        return node
    }

    /// Tapered mesh, rather than overlapping spheres or a flat jacket image.
    private static func tailoredTorso(color: UIColor) -> SCNNode {
        let rings: [(Float, Float, Float)] = [
            (1.13, 0.165, 0.090), (1.22, 0.179, 0.115),
            (1.38, 0.195, 0.123), (1.51, 0.228, 0.123),
            (1.60, 0.203, 0.110), (1.66, 0.095, 0.076)
        ]
        let slices = 20
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        for (y, rx, rz) in rings {
            for k in 0..<slices {
                let t = Float(k) / Float(slices) * 2 * Float.pi
                let co = cos(t)
                let si = sin(t)
                vertices.append(SCNVector3(co * rx, y, si * rz))
                let nx = co / rx, nz = si / rz
                let d = sqrt(nx * nx + nz * nz)
                normals.append(SCNVector3(nx / d, 0, nz / d))
            }
        }
        var indices: [Int32] = []
        for row in 0..<(rings.count - 1) {
            for k in 0..<slices {
                let a = Int32(row * slices + k)
                let b = Int32(row * slices + (k + 1) % slices)
                let c = Int32((row + 1) * slices + k)
                let d = Int32((row + 1) * slices + (k + 1) % slices)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        let source = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let elements = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geo = SCNGeometry(sources: [source, normalSource], elements: [elements])
        geo.firstMaterial = material(color, roughness: 0.88)
        geo.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: geo)
        node.name = "3D tailored jacket"
        return node
    }

    private static func coatColor(_ id: String?) -> UIColor {
        switch id {
        case "coat_navy": return UIColor(red: 0.15, green: 0.32, blue: 0.53, alpha: 1)
        case "coat_crimson": return UIColor(red: 0.49, green: 0.16, blue: 0.23, alpha: 1)
        case "coat_ghost": return UIColor(red: 0.74, green: 0.79, blue: 0.83, alpha: 1)
        case "coat_royal": return UIColor(red: 0.27, green: 0.22, blue: 0.48, alpha: 1)
        case "coat_sand": return UIColor(red: 0.59, green: 0.45, blue: 0.30, alpha: 1)
        case "coat_evergreen": return UIColor(red: 0.18, green: 0.32, blue: 0.26, alpha: 1)
        case "coat_noir": return UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1)
        case "coat_arctic": return UIColor(red: 0.67, green: 0.77, blue: 0.82, alpha: 1)
        case "coat_sunset": return UIColor(red: 0.60, green: 0.29, blue: 0.19, alpha: 1)
        case "coat_cipher": return UIColor(red: 0.15, green: 0.18, blue: 0.37, alpha: 1)
        default: return UIColor(red: 0.19, green: 0.235, blue: 0.29, alpha: 1)
        }
    }

    private static func makeFace(into head: SCNNode, skin: UIColor) {
        head.addChildNode(ellipsoid("Skull", skin, 0, 0.135, 0,
                                    0.110, 0.153, 0.098, roughness: 0.86))
        head.addChildNode(ellipsoid("Jaw", skin, 0, 0.073, 0.023,
                                    0.082, 0.070, 0.089, roughness: 0.88))
        for side in [-1.0, 1.0] {
            let s = Float(side)
            head.addChildNode(ellipsoid("Ear", skin, s * 0.108, 0.124, 0.007,
                                        0.019, 0.033, 0.016))
            head.addChildNode(ellipsoid("Upper cheek", skin, s * 0.055,
                                       0.121, 0.070, 0.047, 0.044, 0.033))
            head.addChildNode(ellipsoid("Eye white",
                             UIColor(red: 0.91, green: 0.89, blue: 0.85, alpha: 1),
                             s * 0.043, 0.161, 0.102,
                             0.024, 0.013, 0.008, roughness: 0.28))
            head.addChildNode(ellipsoid("Iris",
                             UIColor(red: 0.25, green: 0.36, blue: 0.40, alpha: 1),
                             s * 0.043, 0.160, 0.111,
                             0.008, 0.009, 0.004, roughness: 0.24))
            head.addChildNode(ellipsoid("Pupil",
                             UIColor(red: 0.037, green: 0.032, blue: 0.03, alpha: 1),
                             s * 0.043, 0.159, 0.116,
                             0.0035, 0.005, 0.002, roughness: 0.20))
            let brow = box("Eyebrow", hairColor,
                           width: 0.044, height: 0.007, length: 0.010,
                           x: s * 0.044, y: 0.189, z: 0.106, chamfer: 0.004)
            brow.eulerAngles.z = -s * 0.06
            head.addChildNode(brow)
        }
        head.addChildNode(ellipsoid("Nose bridge", skin, 0, 0.139, 0.103,
                                    0.017, 0.036, 0.023))
        head.addChildNode(ellipsoid("Nose tip", skin, 0, 0.116, 0.124,
                                    0.022, 0.015, 0.020))
        head.addChildNode(ellipsoid("Mouth", UIColor(red: 0.39, green: 0.22,
                                    blue: 0.21, alpha: 1), 0, 0.075, 0.109,
                                    0.030, 0.004, 0.003))
        head.addChildNode(ellipsoid("Lower lip", skin.withAlphaComponent(0.98),
                                    0, 0.066, 0.108, 0.025, 0.005, 0.003))
    }

    private static func makeHair(into head: SCNNode, style: DetectiveHair) {
        let topY: Float = style == .cropped ? 0.247 : 0.265
        head.addChildNode(ellipsoid("Hair foundation", hairColor, 0, topY, -0.004,
                                    0.114, style == .cropped ? 0.037 : 0.062,
                                    0.105, roughness: 0.93))
        let count = style == .cropped ? 9 : style == .textured ? 19 : 13
        for i in 0..<count {
            let angle = Float(i) * 2.39996
            let radius = Float(sqrt(Double(i) / Double(count))) * 0.087
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let frontShift: Float = style == .swept ? 0.018 : 0
            let height: Float = style == .textured ? Float(i % 5) * 0.009 : 0
            let tuft = ellipsoid("Hair strand clump", hairColor,
                                  x + frontShift, topY + 0.025 + height, z,
                                  0.027, style == .cropped ? 0.013 : 0.033,
                                  0.032, roughness: 0.95)
            tuft.eulerAngles.z = style == .swept ? -0.29 : Float(i % 3 - 1) * 0.09
            head.addChildNode(tuft)
        }
    }

    private static func makeEyewear(into head: SCNNode, id: String?) {
        guard let id else { return }
        let dark = UIColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1)
        let frame: UIColor = id == "glasses_clear" ? metal :
                             id == "glasses_monocle" ? UIColor(red: 0.78, green: 0.61, blue: 0.32, alpha: 1)
                             : dark
        let shield = ["glasses_visor", "glasses_night", "glasses_ice", "glasses_holo"]
        if shield.contains(id) {
            let glass = box("3D eye visor", UIColor(red: 0.15, green: 0.33,
                            blue: 0.40, alpha: 0.88),
                            width: 0.177, height: 0.046, length: 0.015,
                            x: 0, y: 0.161, z: 0.128, chamfer: 0.014)
            glass.geometry?.firstMaterial?.transparency = id == "glasses_holo" ? 0.60 : 0.88
            head.addChildNode(glass)
            return
        }
        let monocle = id == "glasses_monocle"
        for side in [-1.0, 1.0] where !monocle || side == 1 {
            let lens = SCNTorus(ringRadius: 0.026, pipeRadius: 0.003)
            lens.firstMaterial = material(frame, roughness: 0.30, metalness: 0.7)
            let rim = SCNNode(geometry: lens)
            rim.name = "Real 3D eyeglass frame"
            rim.position = SCNVector3(Float(side) * 0.045, 0.159, 0.122)
            rim.eulerAngles.x = .pi / 2
            head.addChildNode(rim)
            if id == "glasses_amber" || id == "glasses_ruby" {
                let tint = id == "glasses_ruby" ? UIColor.systemRed : UIColor.systemOrange
                let lens = ellipsoid("Tinted lens", tint.withAlphaComponent(0.20),
                                    Float(side) * 0.045, 0.159, 0.122,
                                    0.023, 0.022, 0.0015, roughness: 0.17)
                lens.geometry?.firstMaterial?.transparency = 0.25
                head.addChildNode(lens)
            }
        }
        if !monocle {
            head.addChildNode(box("3D spectacle bridge", frame, width: 0.035,
                                  height: 0.004, length: 0.006,
                                  x: 0, y: 0.162, z: 0.123, chamfer: 0.001))
        }
    }

    private static func makeHeadwear(into head: SCNNode, id: String?) {
        guard let id else { return }
        let fabric: UIColor
        switch id {
        case "hat_beret": fabric = UIColor(red: 0.34, green: 0.10, blue: 0.14, alpha: 1)
        case "hat_newsboy": fabric = UIColor(red: 0.40, green: 0.31, blue: 0.22, alpha: 1)
        case "hat_winter": fabric = UIColor(red: 0.75, green: 0.80, blue: 0.85, alpha: 1)
        case "hat_visor": fabric = UIColor(red: 0.11, green: 0.32, blue: 0.28, alpha: 1)
        case "hat_cap": fabric = UIColor(red: 0.15, green: 0.24, blue: 0.33, alpha: 1)
        default: fabric = UIColor(red: 0.09, green: 0.12, blue: 0.16, alpha: 1)
        }
        if id == "hat_fedora" {
            let crown = SCNCylinder(radius: 0.092, height: 0.093)
            crown.firstMaterial = material(fabric)
            let cap = SCNNode(geometry: crown)
            cap.position = SCNVector3(0, 0.319, 0)
            head.addChildNode(cap)
            let brim = SCNCylinder(radius: 0.147, height: 0.012)
            brim.firstMaterial = material(fabric)
            let rim = SCNNode(geometry: brim)
            rim.position = SCNVector3(0, 0.278, 0.01)
            head.addChildNode(rim)
        } else if id == "hat_beret" {
            head.addChildNode(ellipsoid("3D wool beret", fabric, -0.017, 0.294, 0,
                                       0.142, 0.036, 0.114))
        } else if id == "hat_hood" {
            head.addChildNode(ellipsoid("3D hood behind head", fabric, 0, 0.179, -0.066,
                                       0.140, 0.175, 0.080))
        } else {
            head.addChildNode(ellipsoid("3D cap crown", fabric, 0, 0.289, -0.005,
                                       0.116, 0.057, 0.110))
            if id != "hat_beanie" && id != "hat_winter" {
                let brim = box("3D visor brim", fabric,
                                width: 0.184, height: 0.011, length: 0.075,
                                x: 0, y: 0.281, z: 0.113, chamfer: 0.008)
                head.addChildNode(brim)
            }
        }
    }

    private static func makeBadge(into body: SCNNode, id: String?) {
        guard let id else { return }
        let gold = id.contains("bronze") ? UIColor(red: 0.62, green: 0.40,
                                                  blue: 0.22, alpha: 1) :
                   id.contains("silver") || id.contains("diamond")
                     ? metal : UIColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 1)
        let shield = box("Metal agency badge", gold,
                         width: 0.047, height: 0.058, length: 0.008,
                         x: 0.142, y: 1.522, z: 0.146, chamfer: 0.010,
                         metalness: 0.94)
        body.addChildNode(shield)
        body.addChildNode(ellipsoid("Badge emblem", metal,
                                    0.142, 1.528, 0.152,
                                    0.010, 0.011, 0.003, roughness: 0.24))
    }

    private static func light(at position: SCNVector3, intensity: CGFloat,
                              color: UIColor) -> SCNNode {
        let node = SCNNode()
        let l = SCNLight()
        l.type = .omni
        l.color = color
        l.intensity = intensity
        node.light = l
        node.position = position
        return node
    }
}
