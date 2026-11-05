import AppKit
import ApplicationServices
import PingCore

/// Only owns mouse sequences that started with Option alone. Never records input.
final class OptionDrag {
    weak var owner: AppDelegate?
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var gesture = DragGesture()
    var enabled: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }
    init(owner: AppDelegate) { self.owner = owner }

    @discardableResult func start() -> Bool {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true); return true }
        guard AXIsProcessTrusted() else { return false }
        let types: [CGEventType] = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDown, .rightMouseDragged, .rightMouseUp, .flagsChanged]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let hook = Unmanaged<OptionDrag>.fromOpaque(context).takeUnretainedValue()
            return hook.handle(type, event: event) ? nil : Unmanaged.passUnretained(event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        tap = port
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }
    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil
        gesture = DragGesture()
    }
    func cancel() { gesture.cancel() }
    func handle(_ type: CGEventType, event: CGEvent) -> Bool {
        guard let owner else { return false }
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            gesture.cancel(); owner.hideWheel()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        let flags = event.flags
        let option = flags.contains(.maskAlternate)
        let other = !flags.intersection([.maskCommand, .maskControl, .maskShift, .maskSecondaryFn]).isEmpty
        let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0
        let point = NSPoint(x: event.location.x, y: primaryTop - event.location.y)
        switch type {
        case .leftMouseDown:
            if gesture.ownsMouse {
                _ = gesture.finish(dx: 0, dy: 0, option: false, otherModifiers: false)
                owner.hideWheel()
            }
            guard gesture.begin(option: option, otherModifiers: other, paused: owner.isPaused || owner.wheel != nil) else { return false }
            owner.anchor = point
            let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
            owner.wheelScale = WheelGeometry.scale(screenHeight: Double(screen?.frame.height ?? 1080))
            return true
        case .leftMouseDragged:
            guard gesture.ownsMouse else { return false }
            if !option || other { gesture.cancel(); owner.hideWheel() }
            gesture.move(dx: (point.x-owner.anchor.x)/owner.wheelScale, dy: (point.y-owner.anchor.y)/owner.wheelScale)
            if !gesture.cancelled && gesture.hasDragged && owner.wheel == nil {
                owner.openWheel(at: owner.anchor, dragging: true)
                if owner.wheel == nil { gesture.cancel() }
            }
            if !gesture.cancelled, let view = owner.wheel?.contentView as? WheelView {
                view.selected = WheelGeometry.selection(dx: point.x - owner.anchor.x, dy: point.y - owner.anchor.y, scale: owner.wheelScale, bounded: false)
            }
            return true
        case .leftMouseUp:
            let owned = gesture.ownsMouse
            guard owned else { return false }
            let ping = gesture.finish(dx: (point.x - owner.anchor.x) / owner.wheelScale, dy: (point.y - owner.anchor.y) / owner.wheelScale, option: option, otherModifiers: other)
            owner.hideWheel()
            if let ping { owner.emit(ping) }
            return true
        case .rightMouseDown:
            let consumed = gesture.rightDown()
            if consumed { owner.hideWheel() }
            return consumed
        case .rightMouseDragged:
            return gesture.ownsRightMouse
        case .rightMouseUp:
            return gesture.rightUp()
        case .flagsChanged:
            if gesture.ownsMouse && (!option || other) { gesture.cancel(); owner.hideWheel() }
            return false
        default: return false
        }
    }
    deinit { stop() }
}
