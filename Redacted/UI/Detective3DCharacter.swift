import SceneKit
import Metal
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

/// Static item-only renders of the *same SceneKit meshes* as the actor.
/// One 320px Metal snapshot per cosmetic ID is cached so a scrolling grid
/// never creates dozens of continuously-rendering 3D characters.
struct CosmeticItemThumbnail: View {
    let item: DetectiveCosmetic
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(7)
                    .transition(.opacity)
            } else {
                ProgressView()
                    .tint(Art.cyan)
                    .accessibilityLabel("Rendering cosmetic preview")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: item.id) {
            if let saved = CosmeticPreviewCache.cached(item.id) {
                image = saved
                return
            }
            image = nil
            // Allows the item grid to paint before starting its first
            // GPU snapshot. All subsequent appearances use the cache.
            await Task.yield()
            guard !Task.isCancelled else { return }
            image = CosmeticPreviewCache.render(item)
        }
        .accessibilityHidden(true)
    }
}

@MainActor
private enum CosmeticPreviewCache {
    private static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 48
        return cache
    }()

    static func cached(_ id: String) -> UIImage? {
        images.object(forKey: id as NSString)
    }

    static func render(_ item: DetectiveCosmetic) -> UIImage? {
        if let old = cached(item.id) { return old }
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let scene = DetectiveModelFactory.makeCosmeticPreview(item)
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.autoenablesDefaultLighting = false
        renderer.pointOfView = scene.rootNode.childNode(
            withName: "Cosmetic product camera", recursively: false)
        let result = renderer.snapshot(
            atTime: 0,
            with: CGSize(width: 320, height: 320),
            antialiasingMode: .multisampling4X)
        images.setObject(result, forKey: item.id as NSString)
        return result
    }
}

private enum DetectiveModelFactory {
    private static let navy = UIColor(red: 0.14, green: 0.18, blue: 0.24, alpha: 1)
    private static let fabricDark = UIColor(red: 0.085, green: 0.11, blue: 0.16, alpha: 1)
    private static let shirt = UIColor(red: 0.64, green: 0.68, blue: 0.72, alpha: 1)
    private static let metal = UIColor(red: 0.78, green: 0.81, blue: 0.85, alpha: 1)
    private static let hairColor = UIColor(red: 0.105, green: 0.078, blue: 0.065, alpha: 1)

    /// Item only, never a disguised cropped avatar or a generic SF Symbol.
    /// Every slot calls the same mesh builders used in `make(skin:...)`.
    static func makeCosmeticPreview(_ item: DetectiveCosmetic) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let product = SCNNode()
        product.name = "Isolated cosmetic"
        scene.rootNode.addChildNode(product)
        let geometry = SCNNode()
        product.addChildNode(geometry)

        switch item.slot {
        case .headwear:
            makeHeadwear(into: geometry, id: item.id)
            // Original head-local headwear center is around y=0.30.
            geometry.position = SCNVector3(0, -0.30, 0)
            product.scale = SCNVector3(1.65, 1.65, 1.65)

        case .eyewear:
            makeEyewear(into: geometry, id: item.id)
            geometry.position = SCNVector3(0, -0.16, -0.125)
            product.scale = SCNVector3(2.15, 2.15, 2.15)

        case .badge:
            makeBadge(into: geometry, id: item.id)
            // Badges live on the torso at (0.13, 1.52, 0.19).
            geometry.position = SCNVector3(-0.13, -1.52, -0.19)
            product.scale = SCNVector3(5.0, 5.0, 5.0)

        case .coat:
            let jacket = coatColor(item.id)
            geometry.addChildNode(tailoredTorso(color: jacket))
            for side in [-1.0, 1.0] {
                geometry.addChildNode(segment("Coat sleeve", jacket,
                    from: SCNVector3(Float(side) * 0.224, 1.560, 0),
                    to: SCNVector3(Float(side) * 0.260, 1.205, 0.014),
                    radius: 0.073))
                let lapel = box("Matching coat lapel", jacket,
                                width: 0.067, height: 0.215, length: 0.024,
                                x: Float(side) * 0.092, y: 1.517, z: 0.144,
                                chamfer: 0.011)
                lapel.eulerAngles.z = Float(side) * -0.15
                geometry.addChildNode(lapel)
            }
            makeCoatDetails(into: geometry, id: item.id, base: jacket)
            geometry.position = SCNVector3(0, -1.415, 0)
            product.scale = SCNVector3(0.93, 0.93, 0.93)
        }

        // Rotate just enough to reveal the item depth and silhouette.
        product.eulerAngles.y = 0.18

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 130
        ambient.light?.color = UIColor(white: 0.92, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        scene.rootNode.addChildNode(light(
            at: SCNVector3(-1.0, 1.5, 2.6), intensity: 590,
            color: UIColor(red: 1.0, green: 0.95, blue: 0.91, alpha: 1)))
        scene.rootNode.addChildNode(light(
            at: SCNVector3(1.0, 0.8, -1.2), intensity: 210,
            color: UIColor(red: 0.62, green: 0.77, blue: 1.0, alpha: 1)))

        let camera = SCNNode()
        camera.name = "Cosmetic product camera"
        camera.camera = SCNCamera()
        camera.camera?.wantsHDR = false
        camera.camera?.wantsExposureAdaptation = false
        camera.camera?.fieldOfView = 35
        camera.camera?.zNear = 0.02
        camera.position = SCNVector3(0, 0.03, 1.18)
        camera.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camera)
        return scene
    }

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
            mannequin.addChildNode(skinEllipsoid("Hand", color,
                                            Float(side) * 0.255, 0.885, 0.035,
                                            0.038, 0.075, 0.030))
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
        makeCoatDetails(into: mannequin, id: equipment[.coat], base: jacket)
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
        mannequin.addChildNode(skinEllipsoid("Neck", color, 0, 1.690, 0,
                                        0.068, 0.080, 0.068))

        // Pivot allows the entire head, hair, eyes and worn accessories to
        // animate together. Nothing is pasted onto a flat render.
        let head = SCNNode()
        head.name = "Head and equipment joint"
        head.position = SCNVector3(0, 1.700, 0)
        mannequin.addChildNode(head)
        makeFace(into: head, skin: color)
        makeHair(into: head, style: hair,
                 wearingHeadwear: equipment[.headwear] != nil)
        makeEyewear(into: head, id: equipment[.eyewear])
        makeHeadwear(into: head, id: equipment[.headwear])
        makeBadge(into: mannequin, id: equipment[.badge])

        if animated {
            startNaturalIdle(head: head, body: mannequin)
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
        ambient.light?.intensity = 78
        ambient.light?.color = UIColor(white: 0.82, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = light(at: SCNVector3(-2.0, 3.0, 3.2),
                        intensity: 290, color: UIColor(red: 1, green: 0.94,
                                                        blue: 0.88, alpha: 1))
        key.light?.castsShadow = true
        key.light?.shadowRadius = 9
        key.light?.shadowSampleCount = 12
        scene.rootNode.addChildNode(key)
        scene.rootNode.addChildNode(light(at: SCNVector3(2.3, 2.6, -1.5),
                                        intensity: 105,
                                        color: UIColor(red: 0.47, green: 0.69,
                                                       blue: 0.88, alpha: 1)))

        let camera = SCNNode()
        camera.name = "Detective camera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = closeup ? 37 : 34
        camera.camera?.wantsHDR = false
        camera.camera?.exposureOffset = -0.50
        camera.camera?.wantsExposureAdaptation = false
        camera.position = closeup
            ? SCNVector3(0, 1.80, 1.08)
            : SCNVector3(0, 1.12, 3.55)
        camera.look(at: closeup ? SCNVector3(0, 1.78, 0)
                                : SCNVector3(0, 1.04, 0))
        camera.camera?.zNear = 0.025
        scene.rootNode.addChildNode(camera)
        return scene
    }

    /// Light random micro-movements keep the actor alive without a looping
    /// robot-like pose. All children (hair and equipment) move with the head.
    private static func startNaturalIdle(head: SCNNode, body: SCNNode) {
        let inhale = SCNAction.moveBy(x: 0, y: 0.0035, z: 0, duration: 2.7)
        let exhale = SCNAction.moveBy(x: 0, y: -0.0035, z: 0, duration: 3.1)
        inhale.timingMode = .easeInEaseOut
        exhale.timingMode = .easeInEaseOut
        body.runAction(.repeatForever(.sequence([inhale, exhale])),
                       forKey: "breathing")

        let nextLook = SCNAction.run { node in
            let x = CGFloat.random(in: -0.020...0.028)
            let y = CGFloat.random(in: -0.075...0.075)
            let z = CGFloat.random(in: -0.018...0.018)
            let motion = SCNAction.rotateTo(
                x: x, y: y, z: z,
                duration: TimeInterval.random(in: 0.75...1.5),
                usesShortestUnitArc: true
            )
            motion.timingMode = .easeInEaseOut
            node.runAction(motion, forKey: "idleLook")
        }
        head.runAction(.repeatForever(.sequence([
            .wait(duration: 2.2, withRange: 3.2), nextLook
        ])), forKey: "idleLookScheduler")

        let nextBlink = SCNAction.run { node in
            let lids = node.childNodes.filter { $0.name == "Upper eyelid" }
            let close = SCNAction.moveBy(x: 0, y: -0.012, z: 0, duration: 0.09)
            let open = SCNAction.moveBy(x: 0, y: 0.012, z: 0, duration: 0.12)
            close.timingMode = .easeIn
            open.timingMode = .easeOut
            for lid in lids {
                lid.runAction(.sequence([close, open]), forKey: "blink")
            }
        }
        head.runAction(.repeatForever(.sequence([
            .wait(duration: 2.0, withRange: 3.4), nextBlink
        ])), forKey: "blinkScheduler")
    }

    /// Skin is the literal selected palette color with *diffuse only*
    /// shading. PBR specular highlights had clipped light skin to white.
    /// This matte material preserves the tone selected in Style Lab.
    private static func skinMaterial(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .lambert
        m.diffuse.contents = color
        m.ambient.contents = UIColor(white: 0.22, alpha: 1)
        m.emission.contents = UIColor.black
        m.isDoubleSided = false
        return m
    }

    private static func skinEllipsoid(_ name: String, _ color: UIColor,
                                      _ x: Float, _ y: Float, _ z: Float,
                                      _ rx: CGFloat, _ ry: CGFloat, _ rz: CGFloat) -> SCNNode {
        let node = ellipsoid(name, color, x, y, z, rx, ry, rz)
        node.geometry?.firstMaterial = skinMaterial(color)
        return node
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
        head.addChildNode(skinEllipsoid("Skull", skin, 0, 0.134, 0,
                                    0.104, 0.145, 0.098))
        head.addChildNode(skinEllipsoid("Jaw", skin, 0, 0.075, 0.020,
                                    0.080, 0.063, 0.079))
        for side in [-1.0, 1.0] {
            let s = Float(side)
            head.addChildNode(skinEllipsoid("Ear", skin, s * 0.103, 0.125, 0.005,
                                        0.014, 0.025, 0.014))
            head.addChildNode(skinEllipsoid("Upper cheek", skin, s * 0.053,
                                       0.121, 0.060, 0.038, 0.031, 0.023,
                                       roughness: 0.93))
            head.addChildNode(ellipsoid("Eye white",
                             UIColor(red: 0.91, green: 0.89, blue: 0.85, alpha: 1),
                             s * 0.043, 0.161, 0.102,
                             0.020, 0.010, 0.008))
            head.addChildNode(ellipsoid("Iris",
                             UIColor(red: 0.25, green: 0.36, blue: 0.40, alpha: 1),
                             s * 0.043, 0.160, 0.111,
                             0.0065, 0.0070, 0.004, roughness: 0.32))
            head.addChildNode(ellipsoid("Pupil",
                             UIColor(red: 0.037, green: 0.032, blue: 0.03, alpha: 1),
                             s * 0.043, 0.159, 0.116,
                             0.0032, 0.0038, 0.002, roughness: 0.28))
            // Stable upper eyelid: a small real box in head-local units,
            // animated by millimeters, never by changing the node's scale.
            // The old implementation multiplied an ellipsoid scale of 0.0008
            // up to 1.0, producing the giant white bars across the face.
            let lid = box("Upper eyelid", skin,
                          width: 0.043, height: 0.006, length: 0.006,
                          x: s * 0.043, y: 0.175, z: 0.120,
                          chamfer: 0.002)
            lid.geometry?.firstMaterial = skinMaterial(skin)
            head.addChildNode(lid)
            let brow = box("Eyebrow", hairColor,
                           width: 0.043, height: 0.005, length: 0.008,
                           x: s * 0.044, y: 0.189, z: 0.106, chamfer: 0.004)
            brow.eulerAngles.z = -s * 0.06
            head.addChildNode(brow)
        }
        head.addChildNode(skinEllipsoid("Nose bridge", skin, 0, 0.136, 0.101,
                                    0.013, 0.029, 0.018))
        head.addChildNode(skinEllipsoid("Nose tip", skin, 0, 0.113, 0.117,
                                    0.018, 0.013, 0.015))
        head.addChildNode(ellipsoid("Mouth", UIColor(red: 0.39, green: 0.22,
                                    blue: 0.21, alpha: 1), 0, 0.075, 0.109,
                                    0.024, 0.003, 0.003))
        head.addChildNode(skinEllipsoid("Lower lip", skin,
                                    0, 0.066, 0.108, 0.025, 0.005, 0.003))
    }

    private static func makeHair(into head: SCNNode, style: DetectiveHair,
                                 wearingHeadwear: Bool) {
        // Hair is actually hidden beneath a worn hat. Previously the full
        // crown intersected the hat, making berets and caps float.
        // Short side hair remains at the temples for a natural hairline.
        for side in [-1.0, 1.0] {
            let sideLock = ellipsoid("Hair at temple", hairColor,
                                     Float(side) * 0.091, 0.204, 0.006,
                                     0.018, 0.044, 0.064, roughness: 0.96)
            head.addChildNode(sideLock)
        }
        guard !wearingHeadwear else { return }

        let foundationHeight: CGFloat = style == .cropped ? 0.035 : 0.055
        head.addChildNode(ellipsoid("Scalp hair", hairColor, 0, 0.249, -0.017,
                                    0.107, foundationHeight, 0.102,
                                    roughness: 0.96))
        let count = style == .cropped ? 29 : style == .textured ? 47 : 31
        for i in 0..<count {
            let theta = Float(i) * 2.3999632
            let radius = Float(sqrt(Double(i + 1) / Double(count + 2))) * 0.083
            let x = cos(theta) * radius
            let z = sin(theta) * radius
            let front = z > 0.020
            let offset: Float
            let height: CGFloat
            let breadth: CGFloat
            switch style {
            case .cropped:
                offset = 0
                height = 0.009 + CGFloat(i % 3) * 0.002
                breadth = 0.012
            case .classic:
                offset = x > 0 ? 0.004 : -0.003
                height = 0.017 + CGFloat(i % 3) * 0.003
                breadth = 0.015
            case .textured:
                offset = front ? 0.003 : 0
                height = 0.019 + CGFloat(i % 7) * 0.004
                breadth = 0.012
            case .swept:
                offset = 0.013
                height = front ? 0.025 : 0.017
                breadth = 0.014
            }
            let strand = ellipsoid("Groomed hair strand", hairColor,
                                   x + offset, 0.271 + Float(height) * 0.35, z,
                                   breadth, height, breadth * 1.21,
                                   roughness: 0.96)
            strand.eulerAngles.z = style == .swept ? -0.29 :
                                    style == .classic ? -0.08 : Float(i % 3 - 1) * 0.08
            head.addChildNode(strand)
        }
        if style == .swept || style == .textured {
            let amount = style == .swept ? 10 : 12
            for i in 0..<amount {
                let x = Float(i) / Float(max(1, amount - 1)) * 0.168 - 0.084
                head.addChildNode(ellipsoid("Forehead fringe", hairColor,
                                             x + (style == .swept ? 0.008 : 0),
                                             0.244 + Float(i % 3) * 0.004, 0.087,
                                             0.011, style == .swept ? 0.022 : 0.014,
                                             0.012, roughness: 0.98))
            }
        }
    }

    private static func makeEyewear(into head: SCNNode, id: String?) {
        guard let id else { return }
        let dark = UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 1)
        let steel = UIColor(red: 0.63, green: 0.69, blue: 0.75, alpha: 1)
        if ["glasses_visor", "glasses_night", "glasses_ice", "glasses_holo"].contains(id) {
            let lens: UIColor
            switch id {
            case "glasses_night": lens = UIColor(red: 0.16, green: 0.46, blue: 0.23, alpha: 1)
            case "glasses_ice": lens = UIColor(red: 0.60, green: 0.79, blue: 0.88, alpha: 1)
            case "glasses_holo": lens = UIColor(red: 0.15, green: 0.80, blue: 0.91, alpha: 1)
            default: lens = UIColor(red: 0.15, green: 0.31, blue: 0.42, alpha: 1)
            }
            let wide = id == "glasses_visor" || id == "glasses_holo"
            let glass = box("3D " + id, lens,
                            width: wide ? 0.186 : 0.172,
                            height: wide ? 0.052 : 0.067, length: 0.020,
                            x: 0, y: 0.160, z: 0.126, chamfer: 0.015,
                            metalness: id == "glasses_holo" ? 0.30 : 0.10)
            glass.geometry?.firstMaterial?.transparency = id == "glasses_holo" ? 0.48 : 0.73
            head.addChildNode(glass)
            let band = box("Visor upper frame", dark,
                           width: 0.194, height: 0.008, length: 0.023,
                           x: 0, y: 0.194, z: 0.124, chamfer: 0.004)
            head.addChildNode(band)
            if id == "glasses_night" {
                for side in [-1.0, 1.0] {
                    let optic = SCNCylinder(radius: 0.022, height: 0.022)
                    optic.firstMaterial = material(dark, roughness: 0.3)
                    let node = SCNNode(geometry: optic)
                    node.name = "Night optic barrel"
                    node.eulerAngles.x = .pi / 2
                    node.position = SCNVector3(Float(side) * 0.043, 0.164, 0.149)
                    head.addChildNode(node)
                }
            }
            return
        }

        let mono = id == "glasses_monocle"
        let round = id == "glasses_round" || mono
        let frame = id == "glasses_clear" ? steel :
                    mono ? UIColor(red: 0.84, green: 0.67, blue: 0.32, alpha: 1) :
                    dark
        for side in [-1.0, 1.0] where !mono || side > 0 {
            let geom = SCNTorus(ringRadius: round ? 0.024 : 0.027,
                                pipeRadius: id == "glasses_clear" ? 0.0019 : 0.0032)
            geom.firstMaterial = material(frame, roughness: 0.30, metalness: 0.65)
            let rim = SCNNode(geometry: geom)
            rim.name = "3D " + id + " rim"
            rim.eulerAngles.x = .pi / 2
            if !round { rim.scale.y = 0.77 }
            rim.position = SCNVector3(Float(side) * 0.045, 0.157, 0.119)
            head.addChildNode(rim)
            if id == "glasses_amber" || id == "glasses_ruby" || id == "glasses_clear" {
                let color: UIColor = id == "glasses_ruby" ? UIColor.systemRed :
                                     id == "glasses_amber" ? UIColor.systemOrange : steel
                let lens = ellipsoid("3D " + id + " lens", color,
                                    Float(side) * 0.045, 0.157, 0.123,
                                    0.024, round ? 0.024 : 0.019, 0.0015,
                                    roughness: 0.12)
                lens.geometry?.firstMaterial?.transparency =
                    id == "glasses_clear" ? 0.14 : 0.33
                head.addChildNode(lens)
            }
        }
        if mono {
            let chain = SCNTorus(ringRadius: 0.006, pipeRadius: 0.001)
            chain.firstMaterial = material(frame, roughness: 0.20, metalness: 0.9)
            let charm = SCNNode(geometry: chain)
            charm.eulerAngles.x = .pi / 2
            charm.position = SCNVector3(0.084, 0.089, 0.111)
            head.addChildNode(charm)
        } else {
            head.addChildNode(box("Glasses bridge", frame,
                                  width: 0.037, height: 0.004, length: 0.009,
                                  x: 0, y: 0.164, z: 0.126, chamfer: 0.001))
        }
    }

    private static func makeHeadwear(into head: SCNNode, id: String?) {
        guard let id else { return }
        let black = UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1)
        let gold = UIColor(red: 0.83, green: 0.65, blue: 0.30, alpha: 1)
        let fabric: UIColor
        switch id {
        case "hat_cap": fabric = UIColor(red: 0.14, green: 0.25, blue: 0.36, alpha: 1)
        case "hat_beret": fabric = UIColor(red: 0.40, green: 0.13, blue: 0.20, alpha: 1)
        case "hat_fedora": fabric = black
        case "hat_director": fabric = UIColor(red: 0.16, green: 0.19, blue: 0.27, alpha: 1)
        case "hat_beanie": fabric = UIColor(red: 0.10, green: 0.16, blue: 0.23, alpha: 1)
        case "hat_newsboy": fabric = UIColor(red: 0.43, green: 0.32, blue: 0.22, alpha: 1)
        case "hat_visor": fabric = UIColor(red: 0.13, green: 0.37, blue: 0.36, alpha: 1)
        case "hat_winter": fabric = UIColor(red: 0.72, green: 0.78, blue: 0.84, alpha: 1)
        case "hat_hood": fabric = UIColor(red: 0.09, green: 0.15, blue: 0.20, alpha: 1)
        case "hat_pilot": fabric = UIColor(red: 0.15, green: 0.23, blue: 0.33, alpha: 1)
        default: fabric = black
        }
        switch id {
        case "hat_fedora":
            let crown = SCNCylinder(radius: 0.093, height: 0.082)
            crown.firstMaterial = material(fabric, roughness: 0.92)
            let cap = SCNNode(geometry: crown)
            cap.position = SCNVector3(0, 0.319, 0)
            head.addChildNode(cap)
            let brim = SCNCylinder(radius: 0.150, height: 0.009)
            brim.firstMaterial = material(fabric, roughness: 0.80)
            let rim = SCNNode(geometry: brim)
            rim.position = SCNVector3(0, 0.281, 0.008)
            head.addChildNode(rim)
        case "hat_beret":
            head.addChildNode(ellipsoid("Shadow beret", fabric, -0.027, 0.302, 0.006,
                                        0.143, 0.039, 0.117))
            head.addChildNode(box("Beret stem", black, width: 0.013,
                                  height: 0.018, length: 0.011,
                                  x: -0.015, y: 0.340, z: 0, chamfer: 0.005))
        case "hat_hood":
            head.addChildNode(ellipsoid("Covert hood", fabric, 0, 0.168, -0.076,
                                        0.151, 0.180, 0.105))
            for side in [-1.0, 1.0] {
                head.addChildNode(ellipsoid("Hood fabric edge", fabric,
                                            Float(side) * 0.116, 0.163, 0.053,
                                            0.030, 0.137, 0.036))
            }
        case "hat_visor":
            head.addChildNode(ellipsoid("Field visor band", fabric, 0, 0.253, 0,
                                        0.119, 0.017, 0.102))
            head.addChildNode(box("Visor brim", fabric, width: 0.205,
                                  height: 0.010, length: 0.103,
                                  x: 0, y: 0.249, z: 0.112, chamfer: 0.013))
        case "hat_beanie", "hat_winter":
            head.addChildNode(ellipsoid("Knit cap", fabric, 0, 0.290, -0.003,
                                        0.122, 0.076, 0.111))
            head.addChildNode(ellipsoid("Knit cuff", fabric,
                                        0, 0.260, 0.037, 0.124, 0.022, 0.078))
            if id == "hat_winter" {
                head.addChildNode(ellipsoid("Snow patrol pom", UIColor.white,
                                            0, 0.374, 0, 0.030, 0.030, 0.030))
            }
        case "hat_newsboy":
            head.addChildNode(ellipsoid("Eight-panel newsboy cap", fabric,
                                        0, 0.297, -0.013, 0.140, 0.068, 0.133))
            head.addChildNode(box("Newsboy peak", fabric, width: 0.196,
                                  height: 0.011, length: 0.090,
                                  x: 0, y: 0.264, z: 0.121, chamfer: 0.026))
            head.addChildNode(ellipsoid("Cap button", black, 0, 0.365, 0,
                                        0.015, 0.007, 0.015))
        case "hat_director", "hat_pilot":
            head.addChildNode(ellipsoid("Uniform peaked cap", fabric,
                                        0, 0.297, -0.013, 0.123, 0.069, 0.115))
            head.addChildNode(box("Uniform hat brim", black,
                                  width: 0.210, height: 0.014, length: 0.088,
                                  x: 0, y: 0.270, z: 0.112, chamfer: 0.018))
            head.addChildNode(box("Uniform gold band", gold,
                                  width: 0.178, height: 0.010, length: 0.010,
                                  x: 0, y: 0.283, z: 0.119, chamfer: 0.005,
                                  metalness: 0.67))
            if id == "hat_pilot" {
                head.addChildNode(box("Air marshal insignia", gold,
                                      width: 0.067, height: 0.012, length: 0.012,
                                      x: 0, y: 0.316, z: 0.119, chamfer: 0.004))
            } else {
                head.addChildNode(ellipsoid("Director crest", gold,
                                            0, 0.323, 0.113,
                                            0.021, 0.028, 0.008,
                                            roughness: 0.29))
            }
        default:
            head.addChildNode(ellipsoid("Patrol cap", fabric,
                                        0, 0.289, -0.009, 0.122, 0.063, 0.112))
            head.addChildNode(box("Patrol peak", fabric, width: 0.192,
                                  height: 0.013, length: 0.088,
                                  x: 0, y: 0.267, z: 0.119, chamfer: 0.014))
        }
    }

    private static func makeBadge(into body: SCNNode, id: String?) {
        guard let id else { return }
        let gold = UIColor(red: 0.86, green: 0.69, blue: 0.36, alpha: 1)
        let steel = UIColor(red: 0.82, green: 0.88, blue: 0.92, alpha: 1)
        let metal: UIColor
        let symbol: String
        switch id {
        case "badge_bronze":
            metal = UIColor(red: 0.71, green: 0.43, blue: 0.24, alpha: 1)
            symbol = "★"
        case "badge_silver":
            metal = steel; symbol = "★"
        case "badge_gold":
            metal = gold; symbol = "★"
        case "badge_compass":
            metal = gold; symbol = "✦"
        case "badge_case":
            metal = UIColor(red: 0.31, green: 0.77, blue: 0.89, alpha: 1)
            symbol = "✓"
        case "badge_onyx":
            metal = UIColor(red: 0.20, green: 0.24, blue: 0.29, alpha: 1)
            symbol = "◆"
        case "badge_diamond":
            metal = steel; symbol = "◆"
        case "badge_royal":
            metal = gold; symbol = "♛"
        case "badge_neon":
            metal = UIColor(red: 0.18, green: 0.88, blue: 0.92, alpha: 1)
            symbol = "✦"
        case "badge_director":
            metal = gold; symbol = "♛"
        default:
            metal = gold; symbol = "★"
        }
        let plaque = box("3D " + id + " badge", metal,
                         width: id.contains("royal") || id.contains("director") ? 0.075 : 0.064,
                         height: id.contains("diamond") ? 0.088 : 0.075,
                         length: 0.009,
                         x: 0.130, y: 1.521, z: 0.188,
                         chamfer: 0.010, metalness: 0.87)
        if id == "badge_diamond" {
            plaque.eulerAngles.z = .pi / 4
        }
        body.addChildNode(plaque)
        let engraving = SCNText(string: symbol, extrusionDepth: 0.0015)
        engraving.font = UIFont.systemFont(ofSize: 0.042, weight: .heavy)
        engraving.flatness = 0.001
        engraving.firstMaterial = material(
            id == "badge_onyx" ? steel : UIColor(red: 0.12, green: 0.18, blue: 0.24, alpha: 1),
            roughness: 0.33, metalness: 0.65)
        let mark = SCNNode(geometry: engraving)
        mark.name = id + " distinct emblem"
        mark.scale = SCNVector3(0.83, 0.83, 0.83)
        mark.position = SCNVector3(0.112, 1.505, 0.196)
        body.addChildNode(mark)
    }

    private static func makeCoatDetails(into body: SCNNode, id: String?, base: UIColor) {
        guard let id else { return }
        let gold = UIColor(red: 0.85, green: 0.67, blue: 0.33, alpha: 1)
        let trim: UIColor
        switch id {
        case "coat_ghost", "coat_arctic": trim = UIColor(red: 0.19, green: 0.23, blue: 0.29, alpha: 1)
        case "coat_royal", "coat_cipher": trim = gold
        case "coat_sunset": trim = UIColor(red: 0.97, green: 0.66, blue: 0.31, alpha: 1)
        default: trim = UIColor(red: 0.54, green: 0.61, blue: 0.68, alpha: 1)
        }
        if id == "coat_sand" || id == "coat_noir" || id == "coat_royal" {
            let belt = box(id + " tailored belt", trim,
                           width: 0.330, height: 0.028, length: 0.018,
                           x: 0, y: 1.217, z: 0.122, chamfer: 0.006)
            body.addChildNode(belt)
            for side in [-1.0, 1.0] {
                body.addChildNode(box("Double breasted button", gold,
                           width: 0.013, height: 0.013, length: 0.007,
                           x: Float(side) * 0.055, y: 1.390, z: 0.151,
                           chamfer: 0.004, metalness: 0.8))
            }
        }
        if id == "coat_arctic" {
            let fur = UIColor(red: 0.91, green: 0.93, blue: 0.94, alpha: 1)
            for side in [-1.0, 1.0] {
                body.addChildNode(ellipsoid("Arctic insulated collar", fur,
                                            Float(side) * 0.107, 1.614, 0.093,
                                            0.089, 0.030, 0.062, roughness: 0.98))
            }
        } else if id == "coat_sunset" {
            for side in [-1.0, 1.0] {
                body.addChildNode(ellipsoid("Bomber jacket ribbed collar", trim,
                                            Float(side) * 0.087, 1.610, 0.108,
                                            0.069, 0.023, 0.039))
            }
        } else if id == "coat_evergreen" || id == "coat_cipher" {
            let armPatch = box(id + " sleeve insignia", trim,
                               width: 0.031, height: 0.052, length: 0.009,
                               x: -0.279, y: 1.418, z: 0.070,
                               chamfer: 0.009, metalness: 0.26)
            body.addChildNode(armPatch)
        }
        if id == "coat_crimson" || id == "coat_navy" || id == "coat_ghost" {
            body.addChildNode(box(id + " zipper", trim,
                                  width: 0.007, height: 0.260, length: 0.009,
                                  x: 0.008, y: 1.385, z: 0.157,
                                  chamfer: 0.002, metalness: 0.73))
        }
        if id == "coat_royal" || id == "coat_cipher" {
            body.addChildNode(box(id + " chest insignia", trim,
                                  width: 0.067, height: 0.022, length: 0.010,
                                  x: -0.117, y: 1.533, z: 0.146,
                                  chamfer: 0.006, metalness: 0.78))
        }
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
