import AppKit
import CoreImage

struct ParticleRGB: Hashable {
    let r: CGFloat, g: CGFloat, b: CGFloat
    init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) { self.r = r; self.g = g; self.b = b }
    init(bytes r: CGFloat, _ g: CGFloat, _ b: CGFloat) { self.init(r / 255, g / 255, b / 255) }
    var vector: CIVector { CIVector(x: r, y: g, z: b) }
}

/// Original Source 2 sprite textures from Sqls1/dota2-particles; the PNGs stay unmodified and are recoloured at runtime.
enum ParticleArtwork {
    enum Tint: Hashable {
        /// Untouched pixels, e.g. icons whose dark outlines must survive.
        case original
        /// Additive sprites: emitted intensity becomes alpha, `core` pushes the hottest texels towards white.
        case glow(ParticleRGB, core: CGFloat)
        /// Greyscale icons tinted the way Source 2 applies a colour scale; alpha and dark detail are kept.
        case multiply(ParticleRGB, gain: CGFloat)
    }

    static let names = [
        "beam_generic_2", "aircraft_white", "particle_glow_01", "particle_glow_04", "particle_ring_wave", "flare_01",
        "ping_world_arrow", "ping_ring", "ping_circle_01", "ping_world_highlight", "ping_world",
        "ping_assist", "ping_defend", "ping_heart", "ping_icon_attack", "ping_icon_retreat", "ping_icon_ward",
        "ping_icon_ward_highlight", "arrow_down", "arrow_down_outline_02", "particle_heroring_6_crisp", "valkyrie_ring",
        "beam_generic_7", "particle_cone_variamt_gradient_1", "spark_02", "particle_flare_006_white", "hero_level"
    ]
    static let images: [String: NSImage] = Dictionary(uniqueKeysWithValues: names.map { name in
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Particles"),
              let image = NSImage(contentsOf: url), image.isValid else {
            fatalError("Missing or invalid bundled particle texture: \(name)")
        }
        return (name, image)
    })

    /// Bronze tier 1 maps to atlas sequence 0. Export coordinates are top-left based.
    /// Keep source bytes intact, crop once without tinting or stretching the badge.
    static let bronzeBadge: NSImage = {
        let url = Bundle.module.url(forResource: "hero_level", withExtension: "png", subdirectory: "Particles")!
        let bitmap = NSBitmapImageRep(data: try! Data(contentsOf: url))!
        precondition(bitmap.pixelsWide == 463 && bitmap.pixelsHigh == 656)
        // CGImage uses pixel coordinates, independent of PNG DPI and Retina scale.
        let crop = bitmap.cgImage!.cropping(to: CGRect(x: 203, y: 477, width: 187, height: 163))!
        return NSImage(cgImage: crop, size: NSSize(width: 187, height: 163))
    }()

    static func drawBronzeBadge(center: NSPoint, width: CGFloat, alpha: CGFloat) {
        let height = width * 163 / 187
        bronzeBadge.draw(in: NSRect(x: center.x - width / 2, y: center.y - height / 2,
                                   width: width, height: height),
                         from: .zero, operation: .sourceOver, fraction: max(0, min(1, alpha)))
    }

    static let defaultBlue = ParticleRGB(0.24, 0.58, 1)

    private struct Key: Hashable { let name: String; let tint: Tint }
    private static var cache: [Key: NSImage] = [:]
    private static let context = CIContext()
    private static let glowKernel = CIColorKernel(source: """
        kernel vec4 glow(__sample s, vec3 tint, float core) {
            vec4 c = unpremultiply(s);
            float a = max(c.r, max(c.g, c.b)) * c.a;
            vec3 rgb = mix(tint, vec3(1.0), clamp(core * a * a, 0.0, 1.0));
            return vec4(rgb * a, a);
        }
        """)!
    private static let multiplyKernel = CIColorKernel(source: """
        kernel vec4 tintMultiply(__sample s, vec3 tint, float gain) {
            vec4 c = unpremultiply(s);
            return premultiply(vec4(clamp(c.rgb * tint * gain, 0.0, 1.0), c.a));
        }
        """)!

    static func image(_ name: String, tint: Tint = .original) -> NSImage {
        guard let source = images[name] else { fatalError("Unknown particle texture: \(name)") }
        if case .original = tint { return source }
        let key = Key(name: name, tint: tint)
        if let cached = cache[key] { return cached }
        guard let data = source.tiffRepresentation, let input = CIImage(data: data) else { return source }
        let output: CIImage?
        switch tint {
        case .original: output = input
        case let .glow(color, core): output = glowKernel.apply(extent: input.extent, arguments: [input, color.vector, core])
        case let .multiply(color, gain): output = multiplyKernel.apply(extent: input.extent, arguments: [input, color.vector, gain])
        }
        guard let output, let cgImage = context.createCGImage(output, from: output.extent) else { return source }
        let result = NSImage(cgImage: cgImage, size: source.size)
        cache[key] = result
        return result
    }

    /// `additive` approximates Source 2 ADD blending with Quartz plus-lighter.
    static func draw(_ name: String, center: NSPoint, size: NSSize, alpha: CGFloat = 1, rotation: CGFloat = 0,
                     tint: Tint = .original, additive: Bool = false) {
        let alpha = max(0, min(1, alpha))
        guard alpha > 0.001, size.width > 0, size.height > 0 else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.imageInterpolation = .high
        let t = NSAffineTransform(); t.translateX(by: center.x, yBy: center.y); t.rotate(byDegrees: rotation); t.concat()
        image(name, tint: tint).draw(in: NSRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height),
                                     from: .zero, operation: additive ? .plusLighter : .sourceOver, fraction: alpha)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Legacy entry point: `tinted` meant the default blue intensity-to-alpha glow.
    static func draw(_ name: String, center: NSPoint, size: NSSize, alpha: CGFloat = 1, rotation: CGFloat = 0, tinted: Bool) {
        draw(name, center: center, size: size, alpha: alpha, rotation: rotation,
             tint: tinted ? .glow(defaultBlue, core: 0) : .original, additive: false)
    }

    /// Vertical sprite whose top and bottom fade out, standing in for Source 2 trail head/tail tapering.
    static func drawStreak(_ name: String, rect: NSRect, alpha: CGFloat, tint: Tint,
                           fadeBottom: CGFloat = 0.15, fadeTop: CGFloat = 0.3, additive: Bool = true) {
        let alpha = max(0, min(1, alpha))
        guard alpha > 0.001, rect.width > 0, rect.height > 0, let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.saveGState()
        cg.setAlpha(alpha)
        cg.setBlendMode(additive ? .plusLighter : .normal)
        cg.beginTransparencyLayer(in: rect, auxiliaryInfo: nil)
        cg.clip(to: rect)
        NSGraphicsContext.current?.imageInterpolation = .high
        image(name, tint: tint).draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        let bottom = max(0.001, min(0.49, fadeBottom)), top = max(0.001, min(0.49, fadeTop))
        let components: [CGFloat] = [1, 0, 1, 1, 1, 1, 1, 0]
        let locations: [CGFloat] = [0, bottom, 1 - top, 1]
        if let mask = CGGradient(colorSpace: CGColorSpaceCreateDeviceGray(), colorComponents: components, locations: locations, count: 4) {
            cg.setBlendMode(.destinationIn)
            cg.drawLinearGradient(mask, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        }
        cg.endTransparencyLayer()
        cg.restoreGState()
    }
}
