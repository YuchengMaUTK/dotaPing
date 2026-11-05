import AppKit
import PingCore

/// AppKit approximation of the Source 2 ping particles in particles/ui_mouseactions; layer choice and
/// timings follow the vpcf JSON where readable, everything else is tuned by eye against gameplay capture.
final class SignalView: NSView {
    static let canvas = NSSize(width: 240, height: 360)
    static let ground = NSPoint(x: 120, y: 72)
    /// Kept only for callers that predate per-ping lifetimes; use the instance `duration`.
    static let duration: TimeInterval = 2

    /// Ping lifetimes from scripts/ping_wheel.vdata.
    static func lifetime(for ping: Ping) -> TimeInterval {
        PingAnimation(ping).duration
    }

    let ping: Ping
    let duration: TimeInterval
    var reduceMotionOverride: Bool?
    var progress: CGFloat = 0 { didSet { needsDisplay = true } }

    init(ping: Ping, frame: NSRect) {
        self.ping = ping
        self.duration = Self.lifetime(for: ping)
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private typealias Tint = ParticleArtwork.Tint
    private static let blue = ParticleRGB(bytes: 42, 116, 255)
    private static let light = ParticleRGB(bytes: 206, 235, 255)
    private static let gold = ParticleRGB(bytes: 252, 210, 84)
    private static let rays = ParticleRGB(bytes: 255, 179, 86)
    private static let wardHighlight = ParticleRGB(bytes: 255, 109, 109)
    // Runtime control-point colours are not in the vpcf files; these are matched to capture.
    private static let retreat = ParticleRGB(1, 0.46, 0.1)
    private static let enemyWard = ParticleRGB(1, 0.2, 0.2)
    private static let friendlyWard = ParticleRGB(0.32, 1, 0.2)
    /// Vertical squash for the top-down camera, so ground rings read as lying on the floor.
    private static let groundTilt: CGFloat = 0.62

    private static func ramp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        let v = max(0, min(1, (x - a) / (b - a)))
        return v * v * (3 - 2 * v)
    }
    private static func fract(_ x: CGFloat) -> CGFloat { x - floor(x) }

    override func draw(_ dirtyRect: NSRect) {
        let total = CGFloat(duration)
        let reduced = reduceMotionOverride ?? NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let t = reduced ? min(0.65, total) : max(0, min(1, progress)) * total
        let layers = PingAnimation(ping).layers(at: Double(t))
        switch ping {
        case .enemyVision: drawWard(t: t, layers: layers, color: Self.enemyWard, highlight: Self.wardHighlight)
        case .needVision: drawWard(t: t, layers: layers, color: Self.friendlyWard, highlight: ParticleRGB(0.7, 1, 0.6))
        default: drawBeamPing(t: t, total: total, layers: layers, animated: !reduced)
        }
    }

    // MARK: - Ground-plane sprites

    private func groundSprite(_ name: String, diameter: CGFloat, alpha: CGFloat, tint: Tint, rotation: CGFloat = 0,
                              center: NSPoint = SignalView.ground) {
        let alpha = max(0, min(1, alpha))
        guard alpha > 0.001, diameter > 0 else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.imageInterpolation = .high
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.scaleX(by: 1, yBy: Self.groundTilt)
        transform.rotate(byDegrees: rotation)
        transform.concat()
        ParticleArtwork.image(name, tint: tint).draw(in: NSRect(x: -diameter/2, y: -diameter/2, width: diameter, height: diameter),
                                                     from: .zero, operation: .plusLighter, fraction: alpha)
        NSGraphicsContext.restoreGraphicsState()
    }

    // MARK: - Beam pings (ping_elements_ground + overhead / attack)

    private func drawBeamPing(t: CGFloat, total: CGFloat, layers: PingAnimation.Layers, animated: Bool) {
        let c = Self.ground
        let color = ping == .danger ? Self.retreat : Self.blue
        let life = CGFloat(layers.icon)
        drawGround(t: t, layers: layers, color: color)
        drawBeam(t: t, level: CGFloat(layers.beam), hotspot: CGFloat(layers.hotspot), color: color, animated: animated)

        let icon = NSPoint(x: c.x, y: c.y + 100 + (animated && ping != .onMyWay ? sin(min(1, t / 0.45) * .pi) * 6 : 0))
        switch ping {
        case .attack: drawSwordBurst(t: t, at: icon, color: Self.gold, rayColor: Self.rays, life: life)
        case .danger: drawSwordBurst(t: t, at: icon, color: Self.retreat, rayColor: Self.retreat, life: life)
        case .onMyWay: drawSpinner(t: t, level: CGFloat(layers.ring), color: color)
        default: break
        }
        drawIcon(t: t, at: icon, life: life, color: color, animated: animated)
    }

    private func drawGround(t: CGFloat, layers: PingAnimation.Layers, color: ParticleRGB) {
        let level = CGFloat(layers.hotspot)
        groundSprite("particle_glow_01", diameter: 74, alpha: 0.45 * level, tint: .glow(color, core: 0))
        // The exported solidcircle lives for one second, independent of CP2 icon duration.
        let age = CGFloat(layers.ringAge)
        groundSprite("particle_heroring_6_crisp", diameter: 38 + 132 * age,
                     alpha: 0.65 * CGFloat(layers.ring), tint: .glow(color, core: 0.08))
        if t < 0.6 {
            let age = t / 0.6
            groundSprite("particle_ring_wave", diameter: 34 + age * 110, alpha: 0.42 * (1 - age),
                         tint: .glow(color, core: 0.08))
        }
        groundSprite("flare_01", diameter: 32, alpha: 0.35 * level,
                     tint: .glow(color, core: 0.12), rotation: t * 25)
    }

    /// Approximation only; full Source 2 velocity/position-lock operators are not simulated.
    private func drawBeam(t: CGFloat, level: CGFloat, hotspot: CGFloat, color: ParticleRGB, animated: Bool) {
        guard level > 0.001 else { return }
        let c = Self.ground
        let top: CGFloat = 235
        // Fixed bounds: fade brightness, never retract/crop the column upward.
        let bottom = c.y
        let span = top
        ParticleArtwork.draw("particle_glow_01", center: NSPoint(x: c.x, y: bottom + span / 2), size: NSSize(width: 58, height: span + 24),
                             alpha: 0.24 * level, tint: .glow(color, core: 0), additive: true)
        ParticleArtwork.drawStreak("beam_generic_2", rect: NSRect(x: c.x - 12, y: bottom, width: 24, height: span),
                                   alpha: 0.48 * level, tint: .glow(color, core: 0), fadeBottom: 0.2, fadeTop: 0.55)
        ParticleArtwork.drawStreak("beam_generic_2", rect: NSRect(x: c.x - 2, y: bottom, width: 4, height: span - 15),
                                   alpha: 0.65 * level * (0.3 + 0.7 * hotspot), tint: .glow(color, core: 0.28), fadeBottom: 0.18, fadeTop: 0.5)
        for i in 0..<9 {
            let seed = CGFloat(i)
            let speed: CGFloat = 300 + CGFloat(i % 3) * 40
            let phase = Self.fract((animated ? t : 0.5) * speed / top + seed * 0.381)
            let length: CGFloat = 45 + CGFloat((i * 7) % 5) * 12
            let headY = bottom + span - length - phase * (span - length)
            let x = c.x + sin(seed * 2.399) * 10
            let width: CGFloat = 1.5 + CGFloat(i % 3) * 0.7
            let alpha = 0.55 * sin(min(1, phase * 1.15) * .pi) * level
            ParticleArtwork.drawStreak("beam_generic_2", rect: NSRect(x: x - width/2, y: headY, width: width, height: length),
                                       alpha: alpha, tint: .glow(color, core: 0.12), fadeBottom: 0.35, fadeTop: 0.49)
        }
        ParticleArtwork.draw("aircraft_white", center: NSPoint(x: c.x, y: c.y + 2), size: NSSize(width: 42, height: 42),
                             alpha: 0.7 * hotspot, tint: .glow(color, core: 0.16), additive: true)
    }

    // MARK: - ping_elements_attack (pillar 0.1 s, impact rays 0.2 s, sparks 0.3 s)

    private func drawSwordBurst(t: CGFloat, at icon: NSPoint, color: ParticleRGB, rayColor: ParticleRGB, life: CGFloat) {
        let c = Self.ground
        let pillar = Self.ramp(t, 0.1, 0.22) * (1 - Self.ramp(t, 0.55, 1.1)) * life
        if pillar > 0.001 {
            let width = 46 - 22 * Self.ramp(t, 0.1, 1.1)
            ParticleArtwork.drawStreak("beam_generic_7", rect: NSRect(x: c.x - width/2, y: c.y, width: width, height: 235),
                                       alpha: 0.55 * pillar, tint: .glow(color, core: 0.5), fadeBottom: 0.08, fadeTop: 0.45)
        }
        let burst = Self.ramp(t, 0.15, 0.28) * (1 - Self.ramp(t, 0.45, 1.0)) * life
        ParticleArtwork.draw("particle_glow_04", center: icon, size: NSSize(width: 84, height: 84), alpha: 0.55 * burst,
                             tint: .glow(color, core: 0.4), additive: true)
        ParticleArtwork.draw("particle_flare_006_white", center: icon, size: NSSize(width: 70 + 70 * burst, height: 34),
                             alpha: 0.85 * burst, tint: .glow(color, core: 0.7), additive: true)

        let rays = Self.ramp(t, 0.2, 0.3) * (1 - Self.ramp(t, 0.7, 1.25)) * life
        if rays > 0.001 {
            let grow = 0.6 + 0.4 * Self.ramp(t, 0.2, 0.6)
            for i in 0..<6 {
                let degrees = CGFloat(i) * 60 + 15 + t * 12
                let angle = degrees * .pi / 180
                let length = (52 + CGFloat(i % 2) * 16) * grow
                let center = NSPoint(x: icon.x + cos(angle) * length / 2, y: icon.y + sin(angle) * length / 2)
                ParticleArtwork.draw("particle_cone_variamt_gradient_1", center: center, size: NSSize(width: 26, height: length),
                                     alpha: 0.65 * rays, rotation: degrees - 90, tint: .glow(rayColor, core: 0.3), additive: true)
            }
        }

        let sparkWindow = t - 0.3
        if sparkWindow > 0, sparkWindow < 1.3 {
            for i in 0..<10 {
                let seed = CGFloat(i)
                let age = sparkWindow / (0.9 + Self.fract(seed * 0.618) * 0.4)
                guard age < 1 else { continue }
                let angle = (seed * 137.5 + 20).truncatingRemainder(dividingBy: 360) * .pi / 180
                let speed: CGFloat = 70 + Self.fract(seed * 0.371) * 60
                let vx = cos(angle) * speed, vy = sin(angle) * speed * 0.8 + 30
                let p = NSPoint(x: icon.x + vx * sparkWindow, y: icon.y + vy * sparkWindow - 90 * sparkWindow * sparkWindow)
                let heading = atan2(vy - 180 * sparkWindow, vx) * 180 / .pi
                ParticleArtwork.draw("spark_02", center: p, size: NSSize(width: 16, height: 16), alpha: (1 - age) * life,
                                     rotation: heading - 90, tint: .glow(color, core: 0.8), additive: true)
            }
        }
    }

    /// ping_waypoint_spinner: ping_ring arcs turning on the ground.
    private func drawSpinner(t: CGFloat, level: CGFloat, color: ParticleRGB) {
        let intro = Self.ramp(t, 0.2, 0.5)
        for offset: CGFloat in [0, 120, 240] {
            groundSprite("ping_ring", diameter: 92 + 18 * (1 - intro), alpha: 0.85 * intro * level,
                         tint: .glow(color, core: 0.5), rotation: offset - t * 90)
        }
    }

    // MARK: - Icons (ping_elements_overhead_icon_core / ping_attack_sword_icon)

    private func drawIcon(t: CGFloat, at icon: NSPoint, life: CGFloat, color: ParticleRGB, animated: Bool) {
        let delay: CGFloat = (ping == .attack || ping == .danger) ? 0.1 : 0
        let fade = life
        guard fade > 0.001 else { return }
        let scale = animated ? 1 + 0.35 * (1 - Self.ramp(t, delay, delay + 0.25)) : 1
        let size = 30 * scale
        let center = icon

        ParticleArtwork.draw("particle_glow_04", center: center, size: NSSize(width: 56, height: 56), alpha: 0.2 * fade,
                             tint: .glow(color, core: 0.05), additive: true)
        let box = NSSize(width: size, height: size)
        switch ping {
        case .attention:
            ParticleArtwork.draw("ping_world", center: center, size: box, alpha: fade)
            ParticleArtwork.draw("ping_world_highlight", center: center, size: NSSize(width: size * 1.07, height: size * 1.07),
                                 alpha: 0.35 * fade, tint: .glow(Self.light, core: 0.5), additive: true)
        case .onMyWay:
            // Fixed bronze mastery tier; not a directional arrow or ranked medal.
            ParticleArtwork.drawBronzeBadge(center: center, width: size, alpha: fade)
        case .danger: ParticleArtwork.draw("ping_icon_retreat", center: center, size: box, alpha: fade)
        case .attack: ParticleArtwork.draw("ping_icon_attack", center: center, size: box, alpha: fade)
        case .defend: ParticleArtwork.draw("ping_defend", center: center, size: box, alpha: fade)
        case .help: ParticleArtwork.draw("ping_assist", center: center, size: box, alpha: fade)
        case .heart: ParticleArtwork.draw("ping_heart", center: center, size: box, alpha: fade)
        case .enemyVision, .needVision: break
        }
    }

    // MARK: - Wards (ping_ground_glow + ping_msg_ward_icon): no vertical energy

    private func drawWard(t: CGFloat, layers: PingAnimation.Layers, color: ParticleRGB, highlight: ParticleRGB) {
        let c = Self.ground
        // One ring at once (max particles 1), re-emitted after 1.05 s, radius scaling with normalised age.
        let age = CGFloat(layers.ringAge)
        let ringAlpha = CGFloat(layers.ring)
        let diameter = 40 + 110 * age
        groundSprite("valkyrie_ring", diameter: diameter * 1.76 / 0.85 * 0.6, alpha: 0.5 * ringAlpha, tint: .glow(color, core: 0))
        for rotation: CGFloat in [0, 120, 240] {
            groundSprite("particle_heroring_6_crisp", diameter: diameter, alpha: 0.75 * ringAlpha, tint: .glow(color, core: 0.35),
                         rotation: rotation)
        }

        let fade = CGFloat(layers.icon)
        guard fade > 0.001 else { return }
        let size = 30 * (1 + 0.5 * (1 - Self.ramp(t, 0, 0.25)))
        let icon = NSPoint(x: c.x, y: c.y + 44)
        ParticleArtwork.draw("particle_glow_04", center: icon, size: NSSize(width: size * 1.4, height: size * 1.4), alpha: 0.6 * fade,
                             tint: .multiply(ParticleRGB(0, 0, 0), gain: 1))
        let box = NSSize(width: size, height: size)
        ParticleArtwork.draw("ping_icon_ward", center: icon, size: box, alpha: fade, tint: .multiply(color, gain: 1.6))
        ParticleArtwork.draw("ping_icon_ward_highlight", center: NSPoint(x: icon.x - size * 0.03, y: icon.y), size: box,
                             alpha: 0.5 * fade, tint: .glow(highlight, core: 0.2), additive: true)
    }
}
