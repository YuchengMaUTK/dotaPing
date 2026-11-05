import Foundation

public enum Ping: Int, CaseIterable {
    case attention, danger, onMyWay, defend, attack, enemyVision, needVision, help, heart
    public var title: String { ["DEFAULT PING", "CAUTION", "ON MY WAY", "DEFEND", "ATTACK", "ENEMY WARD", "FRIENDLY WARD", "ASSIST", "HEART"][rawValue] }
}

public enum WheelGeometry {
    // Clockwise from top-right; boundaries lie on cardinal/diagonal rays.
    public static let slots: [Ping] = [.attack, .help, .defend, .needVision, .enemyVision, .heart, .onMyWay, .danger]
    public static func angle(for ping: Ping) -> Double {
        guard let index = slots.firstIndex(of: ping) else { return 0 }
        return (Double(index) + 0.5) * .pi / 4
    }
    public static let deadZone: Double = 35
    public static let outerRadius: Double = 87.5
    /// AppKit coordinates: positive y points up. Clockwise from the top.
    public static func scale(screenHeight: Double) -> Double {
        guard screenHeight.isFinite, screenHeight > 0 else { return 1 }
        return screenHeight / 1080
    }
    public static func selection(dx: Double, dy: Double, scale: Double = 1, bounded: Bool = true) -> Ping? {
        guard scale.isFinite, scale > 0 else { return nil }
        let dx = dx / scale, dy = dy / scale
        guard dx.isFinite, dy.isFinite else { return nil }
        let radius = hypot(dx, dy)
        guard radius >= deadZone, !bounded || radius <= outerRadius else { return nil }
        let angle = atan2(dx, dy)
        let normalized = (angle + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        return slots[Int(normalized / (.pi / 4)) % 8]
    }
    public static func panelOrigin(anchor: Double, lower: Double, upper: Double, size: Double) -> Double {
        max(lower, min(anchor - size / 2, upper - size))
    }
}

/// Retain ownership after cancel, so an intercepted down never leaks an orphan up.
public struct DragGesture {
    public private(set) var ownsMouse = false
    public private(set) var ownsRightMouse = false
    public private(set) var cancelled = false
    public private(set) var hasDragged = false
    public static let clickSlop: Double = 6
    public init() {}
    public mutating func begin(option: Bool, otherModifiers: Bool, paused: Bool) -> Bool {
        guard !ownsMouse, option, !otherModifiers, !paused else { return false }
        ownsMouse = true; cancelled = false; hasDragged = false
        return true
    }
    public mutating func move(dx: Double, dy: Double) {
        guard ownsMouse else { return }
        if !dx.isFinite || !dy.isFinite { cancel(); return }
        if hypot(dx, dy) > Self.clickSlop { hasDragged = true }
    }
    public mutating func cancel() { if ownsMouse { cancelled = true } }
    /// A new right-down clears stale ownership if its previous up was lost.
    public mutating func rightDown() -> Bool {
        ownsRightMouse = false
        guard ownsMouse, !cancelled else { return false }
        ownsRightMouse = true
        cancel()
        return true
    }
    public mutating func rightUp() -> Bool {
        let owned = ownsRightMouse
        ownsRightMouse = false
        return owned
    }
    public mutating func finish(dx: Double, dy: Double, option: Bool, otherModifiers: Bool) -> Ping? {
        move(dx: dx, dy: dy)
        let send = ownsMouse && !cancelled && option && !otherModifiers
        let result: Ping? = send ? (hasDragged ? WheelGeometry.selection(dx: dx, dy: dy, bounded: false) : .attention) : nil
        ownsMouse = false; cancelled = false; hasDragged = false
        return result
    }
}
