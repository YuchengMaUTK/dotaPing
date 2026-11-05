import Foundation

/// Child-layer timeline, not a Source 2 simulation. Curves are sampled linearly from
/// exported normalized-age knots; spatial scale and brightness envelopes are tuned to video.
public struct PingAnimation {
    public let ping: Ping
    public init(_ ping: Ping) { self.ping = ping }
    public var duration: Double { [2, 6, 5, 3, 6, 6, 6, 3, 2][ping.rawValue] }
    public var isWard: Bool { ping == .enemyVision || ping == .needVision }
    public var ringDelay: Double { isWard ? 0 : 0.2 }
    public var ringEnd: Double { ringDelay + 1 }

    public struct Layers {
        public let ring, ringAge, hotspot, beam, icon: Double
    }
    public func layers(at seconds: Double) -> Layers {
        guard seconds.isFinite, seconds >= 0, seconds < duration else {
            return Layers(ring: 0, ringAge: 1, hotspot: 0, beam: 0, icon: 0)
        }
        let t = seconds
        // Ward rings re-emit, but each pulse must actually fade to zero before the next.
        let age = isWard ? t.truncatingRemainder(dividingBy: 1.05) : t - ringDelay
        let ring: Double
        if age < 0 || age >= 1 { ring = 0 }
        else if isWard { ring = Self.curve(age, [(0, 0.02424), (0.17646, 1), (0.63154, 0.27472), (1, 0)]) }
        else { ring = Self.curve(age, [(0, 1), (0.205665, 1), (0.484637, 0.42824), (0.967238, 0)]) }
        let fade = 1 - Self.ramp(t, duration - 0.2, duration)
        let iconDelay = (ping == .attack || ping == .danger) ? 0.1 : 0
        return Layers(ring: ring * fade, ringAge: max(0, min(1, age)),
                      hotspot: isWard ? 0 : Self.ramp(t, 0, 0.12) *
                        (1 - Self.ramp(t, ping == .attention ? duration - 0.35 : 1.3,
                                      ping == .attention ? duration : 2.5)),
                      beam: isWard ? 0 : Self.ramp(t, 0, 0.18) * (1 - Self.ramp(t, duration * 0.85, duration)),
                      icon: Self.ramp(t, iconDelay, iconDelay + (isWard ? 0.636085 : 0.12)) * fade)
    }
    public static func ramp(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let v = max(0, min(1, (t - a) / (b - a)))
        return v * v * (3 - 2 * v)
    }
    private static func curve(_ t: Double, _ knots: [(Double, Double)]) -> Double {
        if t <= knots[0].0 { return knots[0].1 }
        for i in 1..<knots.count where t <= knots[i].0 {
            let (x, y) = knots[i-1], (xx, yy) = knots[i]
            return y + (yy-y) * (t-x) / (xx-x)
        }
        return knots.last!.1
    }
}
