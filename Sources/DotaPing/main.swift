import AppKit
import AVFoundation
import Carbon
import ApplicationServices
import PingCore

let ink = NSColor(calibratedRed: 0.11, green: 0.105, blue: 0.10, alpha: 0.98)
let ivory = NSColor(calibratedRed: 0.92, green: 0.87, blue: 0.76, alpha: 1)
let muted = NSColor(calibratedRed: 0.63, green: 0.59, blue: 0.52, alpha: 1)

extension Ping {
    var color: NSColor {
        switch self {
        case .heart: return NSColor(calibratedRed: 0.76, green: 0.94, blue: 0.31, alpha: 1)
        case .attention: return NSColor(calibratedRed: 0.87, green: 0.91, blue: 0.94, alpha: 1)
        case .danger: return NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.03, alpha: 1)
        case .onMyWay: return NSColor(calibratedRed: 0.65, green: 0.69, blue: 1.0, alpha: 1)
        case .attack: return NSColor(calibratedRed: 1, green: 0.78, blue: 0.18, alpha: 1)
        case .enemyVision: return NSColor(calibratedRed: 1, green: 0.16, blue: 0.19, alpha: 1)
        case .needVision: return NSColor(calibratedRed: 0.25, green: 1, blue: 0.04, alpha: 1)
        case .help: return NSColor(calibratedRed: 0.73, green: 0.91, blue: 0.23, alpha: 1)
        case .defend: return NSColor(calibratedRed: 0.63, green: 0.71, blue: 0.82, alpha: 1)
        }
    }
}

func text(_ value: String, at point: NSPoint, size: CGFloat, color: NSColor, bold: Bool = false) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: bold ? .bold : .medium), .foregroundColor: color
    ]
    let dimensions = (value as NSString).size(withAttributes: attributes)
    (value as NSString).draw(at: NSPoint(x: point.x - dimensions.width / 2, y: point.y - dimensions.height / 2), withAttributes: attributes)
}

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { !ignoresMouseEvents }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    init(frame: NSRect, interactive: Bool) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = !interactive
        acceptsMouseMovedEvents = interactive
    }
}

final class WheelView: NSView {
    var dragMode = false
    var uiScale: CGFloat = 1
    var selected: Ping? { didSet { needsDisplay = true } }
    var choose: ((Ping?) -> Void)?
    private var tracking: NSTrackingArea?
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }
    func selection(at point: NSPoint) -> Ping? {
        WheelGeometry.selection(dx: point.x - bounds.midX, dy: point.y - bounds.midY, scale: uiScale)
    }
    override func mouseMoved(with event: NSEvent) { selected = selection(at: convert(event.locationInWindow, from: nil)) }
    override func mouseExited(with event: NSEvent) { selected = nil }
    override func mouseDown(with event: NSEvent) { choose?(selection(at: convert(event.locationInWindow, from: nil))) }
    override func rightMouseDown(with event: NSEvent) { choose?(nil) }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { choose?(nil); return }
        let physicalKeys: [UInt16: Int] = [18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 87: 4, 88: 5, 89: 6, 91: 7, 83: 0, 84: 1, 85: 2, 86: 3]
        if let index = physicalKeys[event.keyCode] { choose?(WheelGeometry.slots[index]); return }
        if let number = Int(event.charactersIgnoringModifiers ?? ""), (1...8).contains(number) { choose?(WheelGeometry.slots[number - 1]); return }
        if event.keyCode == 36, let selected { choose?(selected); return }
        super.keyDown(with: event)
    }
    override func draw(_ dirtyRect: NSRect) {
        let c = NSPoint(x: bounds.midX, y: bounds.midY)
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let scale = NSAffineTransform(); scale.translateX(by: c.x, yBy: c.y); scale.scale(by: uiScale); scale.translateX(by: -c.x, yBy: -c.y); scale.concat()
        WheelArtwork.draw("background_bottomlayer", center: c, opacity: 0.7)
        WheelArtwork.draw("background", center: c, opacity: 0.4)
        WheelArtwork.draw("backlines", center: c, opacity: 0.3)
        for index in 0..<4 {
            let a = CGFloat(index) * .pi / 2
            let line = NSBezierPath(); line.move(to: NSPoint(x: c.x+sin(a)*33.5,y: c.y+cos(a)*33.5)); line.line(to: NSPoint(x: c.x+sin(a)*87.5,y: c.y+cos(a)*87.5))
            NSColor(white: 0.6, alpha: 0.22).setStroke(); line.lineWidth = 0.6; line.stroke()
        }
        for (index, ping) in WheelGeometry.slots.enumerated() {
            let angle = WheelGeometry.angle(for: ping)
            if selected == ping { WheelArtwork.draw("slicethin_hover", center: c, opacity: 0.9, rotation: CGFloat(90-index*45)) }
            let point = NSPoint(x: c.x+sin(angle)*62.5, y: c.y+cos(angle)*62.5)
            PingArtwork.draw(ping, center: point, size: 35, active: selected == ping)
        }
        WheelArtwork.draw("edge", center: c, opacity: 0.5)
        WheelArtwork.draw("middlebutton", center: c, opacity: 0.5)
        if selected == nil { WheelArtwork.draw("middlebutton_pressed", center: c, opacity: 0.9) }
        WheelArtwork.draw("x", center: c)
        if let selected {
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow(); shadow.shadowColor = .black; shadow.shadowBlurRadius = 3; shadow.shadowOffset = NSSize(width: 3,height: -3); shadow.set()
            text(selected.title, at: NSPoint(x:c.x,y:c.y-120),size:20,color:.white,bold:true)
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var dragHook: OptionDrag?
    var dragItem: NSMenuItem!
    var statusItem: NSStatusItem!
    var wheel: OverlayPanel?
    var signal: OverlayPanel?
    var animation: Timer?
    var dismissTimer: Timer?
    var hotkey: EventHotKeyRef?
    var handler: EventHandlerRef?
    var outsideMonitor: Any?
    var anchor = NSPoint.zero
    var wheelScale: CGFloat = 1
    var isPaused = false
    lazy var audio: PingAudio? = {
        do { return try PingAudio() }
        catch { NSLog("DotaPing audio resources unavailable: \(error)"); return nil }
    }()
    var soundEnabled = !UserDefaults.standard.bool(forKey: "muted")
    var pauseItem: NSMenuItem!
    var soundItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = BrandingArtwork.statusIcon
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.setAccessibilityLabel("DotaPing")
        statusItem.button?.toolTip = "DotaPing · Option + click / drag / ⌘⌥P"
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "DotaPing · Desktop Pings", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Open Ping Wheel  ⌘⌥P", action: #selector(showWheelFromMenu), keyEquivalent: "")
        menu.addItem(withTitle: "Demo Default Ping", action: #selector(demo), keyEquivalent: "")
        dragItem = menu.addItem(withTitle: "Enable Option Gestures…", action: #selector(enableDrag), keyEquivalent: "")
        menu.addItem(.separator())
        soundItem = menu.addItem(withTitle: "Sound", action: #selector(toggleSound), keyEquivalent: "")
        pauseItem = menu.addItem(withTitle: "Pause Ping Gestures", action: #selector(togglePause), keyEquivalent: "")
        menu.addItem(withTitle: "How to Use", action: #selector(help), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit DotaPing", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            if !delegate.isPaused { delegate.showWheel() }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let id = EventHotKeyID(signature: 0x44545047, id: 1)
        let registration = installStatus == noErr ? RegisterEventHotKey(UInt32(kVK_ANSI_P), UInt32(cmdKey | optionKey), id, GetApplicationEventTarget(), 0, &hotkey) : installStatus
        if registration != noErr {
            statusItem.button?.toolTip = "Shortcut registration failed. Open the wheel from the menu."
            let alert = NSAlert()
            alert.messageText = "⌘⌥P is unavailable"
            alert.informativeText = "Another app may be using this shortcut. Open the wheel from the DotaPing menu. Error: \(registration)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        dragHook = OptionDrag(owner: self)
        dragHook?.start()
        if !UserDefaults.standard.bool(forKey: "hasOpened") {
            UserDefaults.standard.set(true, forKey: "hasOpened")
            help()
        }
    }
    func menuWillOpen(_ menu: NSMenu) {
        dragItem.title = dragHook?.enabled == true ? "Option Gestures Enabled" : "Enable Option Gestures…"
        soundItem.state = soundEnabled ? .on : .off
        pauseItem.state = isPaused ? .on : .off
    }
    @objc func enableDrag() {
        if dragHook?.start() == true { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        let alert = NSAlert()
        alert.messageText = "Allow DotaPing Accessibility Access"
        alert.informativeText = "Enable DotaPing in System Settings → Privacy & Security → Accessibility, then choose Enable Option Gestures again. If already enabled, quit and reopen DotaPing. The fallback shortcut ⌘⌥P still works. No keystrokes are recorded."
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    @objc func toggleSound() { soundEnabled.toggle(); if !soundEnabled { audio?.stop() }; UserDefaults.standard.set(!soundEnabled, forKey: "muted") }
    @objc func togglePause() { isPaused.toggle(); hideWheel() }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func help() {
        let alert = NSAlert()
        alert.messageText = "DotaPing"
        alert.informativeText = "Ping your desktop.\n\nHold Option and click for a default ping. Drag to open the wheel; release the mouse to send the selected ping. Once dragging, return to the center to cancel. Dragging beyond the wheel still selects by direction. Right-click cancels; releasing Option first also cancels.\n\nFallback: ⌘⌥P opens the wheel. Click an icon or press 1–8. Esc, right-click or center click cancels.\n\nOption gestures require Accessibility permission. Game-exported artwork and original ping sounds. Desktop particle rendering is approximate. Unofficial local app; does not read the game."
        alert.addButton(withTitle: "Got It")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    @objc func demo() {
        guard let screen = NSScreen.main else { return }
        anchor = NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY)
        emit(.attention)
    }
    @objc func showWheelFromMenu() {
        guard let screen = NSScreen.main else { return }
        openWheel(at: NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY))
    }
    @objc func showWheel() { openWheel(at: NSEvent.mouseLocation) }
    func openWheel(at point: NSPoint, dragging: Bool = false) {
        if wheel != nil { hideWheel(); return }
        anchor = point
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(anchor, $0.frame, false) }) ?? NSScreen.screens.first(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(anchor) }) ?? NSScreen.main else { return }
        let frame = screen.visibleFrame
        wheelScale = WheelGeometry.scale(screenHeight: screen.frame.height)
        let size: CGFloat = max(240, 360 * wheelScale)
        let origin = dragging ? NSPoint(x: point.x - size / 2, y: point.y - size / 2) : NSPoint(x: WheelGeometry.panelOrigin(anchor: anchor.x, lower: frame.minX, upper: frame.maxX, size: size), y: WheelGeometry.panelOrigin(anchor: anchor.y, lower: frame.minY, upper: frame.maxY, size: size))
        let panel = OverlayPanel(frame: NSRect(origin: origin, size: NSSize(width: size, height: size)), interactive: !dragging)
        let view = WheelView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.dragMode = dragging
        view.uiScale = wheelScale
        view.choose = { [weak self] ping in
            self?.hideWheel()
            if let ping { self?.emit(ping) }
        }
        panel.contentView = view
        wheel = panel
        if dragging {
            panel.orderFrontRegardless()
        } else {
            panel.makeKeyAndOrderFront(nil)
            panel.makeFirstResponder(view)
            outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in self?.hideWheel() }
        }
        let timer = Timer(timeInterval: 10, repeats: false) { [weak self] _ in self?.hideWheel() }
        dismissTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    func hideWheel() {
        dragHook?.cancel()
        dismissTimer?.invalidate(); dismissTimer = nil
        if let outsideMonitor { NSEvent.removeMonitor(outsideMonitor) }
        outsideMonitor = nil
        let closingPanel = wheel
        closingPanel?.orderOut(nil); wheel = nil
        DispatchQueue.main.async { withExtendedLifetime(closingPanel) {} }
    }
    func emit(_ ping: Ping) {
        animation?.invalidate()
        signal?.orderOut(nil)
        let panel = OverlayPanel(frame: NSRect(origin:NSPoint(x:anchor.x-SignalView.ground.x,y:anchor.y-SignalView.ground.y),size:SignalView.canvas), interactive: false)
        let view = SignalView(ping: ping, frame: NSRect(origin:.zero,size:SignalView.canvas))
        panel.contentView = view
        signal = panel
        panel.orderFrontRegardless()
        if soundEnabled { audio?.play(ping) }
        let start = ProcessInfo.processInfo.systemUptime
        let duration = view.duration
        let timer = Timer(timeInterval: 1 / 60, repeats: true) { [weak self, weak panel, weak view] timer in
            let progress = min(1, (ProcessInfo.processInfo.systemUptime - start) / duration)
            view?.progress = progress
            // Each particle layer controls its own fade; never fade the whole panel.
            if progress >= 1 {
                timer.invalidate(); panel?.orderOut(nil)
                self?.signal = nil; self?.animation = nil
            }
        }
        animation = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    func applicationWillTerminate(_ notification: Notification) {
        dragHook?.stop()
        audio?.stop()
        hideWheel(); animation?.invalidate()
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
    }
}

func renderPreview(to directory: String) throws {
    let folder = URL(fileURLWithPath: directory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var views: [(String, NSView)] = [("wheel", WheelView(frame: NSRect(x: 0, y: 0, width: 360, height: 360)))]
    for ping in Ping.allCases {
        for (index, seconds) in [0.08, 0.3, 0.65, 1.3, 1.7].enumerated() {
            let view = SignalView(ping: ping, frame: NSRect(origin: .zero, size: SignalView.canvas))
            view.reduceMotionOverride = false
            view.progress = seconds / view.duration
            views.append(("signal-\(ping.rawValue)-frame-\(index)", view))
        }
        let tail = SignalView(ping: ping, frame: NSRect(origin: .zero, size: SignalView.canvas))
        tail.reduceMotionOverride = false
        tail.progress = 0.95
        views.append(("signal-\(ping.rawValue)-tail", tail))
    }
    for (name, view) in views {
        if let wheel = view as? WheelView { wheel.selected = .heart }
        let panel = OverlayPanel(frame: view.bounds, interactive: false)
        panel.contentView = view
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw NSError(domain: "Preview", code: 1) }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        precondition(bitmap.pixelsWide > 0 && bitmap.pixelsHigh > 0)
        let corner = bitmap.colorAt(x: 0, y: 0)!.usingColorSpace(.deviceRGB)!
        precondition(corner.alphaComponent < 0.01, "Opaque canvas corner in \(name)")
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw NSError(domain: "Preview", code: 2) }
        try data.write(to: folder.appendingPathComponent("\(name).png"))
    }
    let cell = NSSize(width: SignalView.canvas.width, height: SignalView.canvas.height + 30)
    for frame in ["frame-0", "frame-1", "frame-2", "frame-3", "frame-4", "tail"] {
        let sheet = NSImage(size: NSSize(width: cell.width * 3, height: cell.height * 3))
        sheet.lockFocus()
        NSColor(white: 0.15, alpha: 1).setFill()
        NSRect(origin: .zero, size: sheet.size).fill()
        for ping in Ping.allCases {
            let x = CGFloat(ping.rawValue % 3) * cell.width
            let y = CGFloat(2 - ping.rawValue / 3) * cell.height
            let image = NSImage(contentsOf: folder.appendingPathComponent("signal-\(ping.rawValue)-\(frame).png"))!
            image.draw(in: NSRect(x: x, y: y, width: cell.width, height: SignalView.canvas.height), from: .zero, operation: .sourceOver, fraction: 1)
            text(ping.title, at: NSPoint(x: x + cell.width / 2, y: y + cell.height - 15), size: 14, color: .white)
        }
        sheet.unlockFocus()
        let sheetBitmap = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
        let name = frame == "frame-2" ? "all-signals" : "all-signals-\(frame)"
        try sheetBitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("\(name).png"))
    }
    print("Rendered wheel and all signals to \(directory)")
}

func runUISelfTest() {
    precondition(BrandingArtwork.statusIcon.isTemplate && BrandingArtwork.statusIcon.size == NSSize(width: 18, height: 18))
    precondition(BrandingArtwork.statusIcon.representations.count == 2)
    if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") {
        precondition(NSImage(contentsOf: iconURL)?.isValid == true)
        precondition(Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String == "AppIcon")
    }
    print("Branding checks passed: original template status icon at 1x/2x and packaged app icon.")
    precondition(PingArtwork.images.count == Ping.allCases.count)
    for image in PingArtwork.images.values {
        precondition(image.isValid && image.size.width >= 64 && image.size.height >= 64)
    }
    precondition(WheelArtwork.images.count == 8 && ParticleArtwork.images.count == ParticleArtwork.names.count)
    for image in Array(WheelArtwork.images.values) + Array(ParticleArtwork.images.values) { precondition(image.isValid) }
    // Compare the runtime bronze crop against the original atlas, including transparent edges.
    let badge = NSBitmapImageRep(data: ParticleArtwork.bronzeBadge.tiffRepresentation!)!
    let atlas = NSBitmapImageRep(data: ParticleArtwork.images["hero_level"]!.tiffRepresentation!)!
    let badgeScale = CGFloat(badge.pixelsWide) / 187
    precondition(ParticleArtwork.bronzeBadge.size == NSSize(width: 187, height: 163))
    for (x, y) in [(0, 0), (93, 20), (70, 70), (93, 140), (186, 162)] {
        let actual = badge.colorAt(x: Int(CGFloat(x) * badgeScale), y: Int(CGFloat(y) * badgeScale))!.usingColorSpace(.deviceRGB)!
        let expected = atlas.colorAt(x: 203 + x, y: 477 + y)!.usingColorSpace(.deviceRGB)!
        precondition(abs(actual.alphaComponent - expected.alphaComponent) < 0.02, "Bronze crop alpha mismatch")
        if expected.alphaComponent > 0.9 {
            precondition(abs(actual.redComponent - expected.redComponent) < 0.03 &&
                         abs(actual.greenComponent - expected.greenComponent) < 0.03 &&
                         abs(actual.blueComponent - expected.blueComponent) < 0.03, "Wrong atlas tier or recoloured bronze")
        }
    }
    print("v0.8.2 bronze badge checks passed: original atlas sequence 0, preserved colour/aspect and transparent edges.")
    print("Bundled PNG checks passed: 9 icons, 8 wheel layers, \(ParticleArtwork.images.count) particle textures.")
    for name in ["beam_generic_2", "particle_glow_01", "flare_01"] {
        let converted = ParticleArtwork.image(name, tint: .glow(ParticleArtwork.defaultBlue, core: 0.5))
        precondition(converted.isValid)
        let bitmap = NSBitmapImageRep(data: converted.tiffRepresentation!)!
        let corner = bitmap.colorAt(x: 0, y: 0)!.usingColorSpace(.deviceRGB)!
        precondition(corner.alphaComponent < 0.1, "Opaque additive background in \(name)")
    }
    for ping in Ping.allCases {
        let effect = SignalView(ping: ping, frame: NSRect(origin: .zero, size: SignalView.canvas))
        let expected = [2.0, 6, 5, 3, 6, 6, 6, 3, 2][ping.rawValue]
        precondition(effect.duration == expected, "Incorrect duration for \(ping.title)")
    }
    // Render actual pixels, not just alpha math: no persistent ring beneath a retained icon.
    for ping in [Ping.attention, .onMyWay, .attack, .defend, .help, .heart] {
        let effect = SignalView(ping: ping, frame: NSRect(origin: .zero, size: SignalView.canvas))
        effect.reduceMotionOverride = false
        let host = OverlayPanel(frame: effect.bounds, interactive: false)
        host.contentView = effect
        func sample(_ seconds: Double) -> (ground: Double, icon: Double, blue: Double, red: Double, lowerBeam: Double) {
            effect.progress = seconds / effect.duration
            let bitmap = effect.bitmapImageRepForCachingDisplay(in: effect.bounds)!
            effect.cacheDisplay(in: effect.bounds, to: bitmap)
            var ground = 0.0, icon = 0.0, blue = 0.0, red = 0.0, lowerBeam = 0.0
            let scale = Double(bitmap.pixelsWide) / Double(effect.bounds.width)
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    let px = Double(x) / scale, py = 360 - Double(y) / scale
                    let c = bitmap.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                    let alpha = Double(c.alphaComponent)
                    if py < 115 && abs(px - 120) > 24 { ground += alpha }
                    if py > 98 && py < 125 && abs(px - 120) < 10 { lowerBeam += alpha }
                    if abs(py - 172) < 20 && abs(px - 120) < 20 { icon += alpha }
                    if py > 205 && py < 265 && abs(px - 120) < 18 {
                        blue += Double(c.blueComponent) * alpha; red += Double(c.redComponent) * alpha
                    }
                }
            }
            return (ground, icon, blue, red, lowerBeam)
        }
        let initial = sample(0.65), retained = sample(1.7), end = sample(effect.duration)
        precondition(initial.ground > 5, "Missing intro ring for \(ping)")
        precondition(retained.ground < initial.ground * 0.05, "Ground ring persisted for \(ping)")
        precondition(retained.lowerBeam > 15, "Column retracted upward from anchor for \(ping)")
        let fading = sample(effect.duration - 0.03)
        precondition(fading.lowerBeam < retained.lowerBeam * 0.5, "Column did not fade for \(ping)")
        precondition(end.lowerBeam < 0.1, "Column remains after end for \(ping)")
        precondition(retained.icon > 20, "Icon faded with ground ring for \(ping)")
        precondition(end.icon < 0.1 && end.ground < 0.1, "Effect did not finish for \(ping)")
        if ping == .attention { precondition(initial.blue > initial.red * 1.5, "Default energy became white") }
    }
    print("v0.8.1 rendered-pixel checks passed: anchored lower beam without upward retraction, independent fade, blue energy, ring/icon separation, clean end.")
    do {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let audio = try PingAudio(manualRenderingFormat: format)
        let expectedEvents = ["General.Ping", "General.PingWarning", "General.PingWaypoint", "General.PingDefense", "General.PingAttack", "General.PingEnemyWard", "General.PingFriendlyWard", "General.Ping", "General.PingHeart"]
        for ping in Ping.allCases {
            precondition(audio.event(for: ping) == expectedEvents[ping.rawValue])
            let duration = audio.duration(of: ping)
            precondition(duration > 0.3 && duration < 10)
            let peak = try audio.renderPeak(ping, seconds: duration + 0.1)
            precondition(peak > 0.001 && peak <= 1, "Silent or clipped original sound: \(ping) \(peak)")
        }
        audio.stop()
        print("v0.8 audio checks passed: all 9 ping mappings and original layered sounds decoded/rendered offline.")
    } catch { preconditionFailure("Bundled audio self-test failed: \(error)") }
    let delegate = AppDelegate()
    delegate.soundEnabled = false
    delegate.showWheel()
    guard let panel = delegate.wheel, let view = panel.contentView as? WheelView else { fatalError("Wheel did not open") }
    precondition(panel.isVisible && !panel.ignoresMouseEvents)
    precondition(panel.firstResponder === view)
    precondition(view.selection(at: NSPoint(x: view.bounds.midX+sin(.pi/8)*60*view.uiScale, y: view.bounds.midY+cos(.pi/8)*60*view.uiScale)) == .attack)
    precondition(view.selection(at: NSPoint(x: view.bounds.midX-sin(.pi/8)*60*view.uiScale, y: view.bounds.midY+cos(.pi/8)*60*view.uiScale)) == .danger)
    let initialAnchor = delegate.anchor
    let key = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: panel.windowNumber, context: nil, characters: "8", charactersIgnoringModifiers: "8", isARepeat: false, keyCode: 28)!
    view.keyDown(with: key)
    precondition(delegate.wheel == nil && delegate.dismissTimer == nil && delegate.outsideMonitor == nil)
    guard let signal = delegate.signal else { fatalError("Signal did not open") }
    precondition(signal.isVisible && signal.ignoresMouseEvents)
    precondition(abs(signal.frame.minX + SignalView.ground.x - initialAnchor.x) <= 1 && abs(signal.frame.minY + SignalView.ground.y - initialAnchor.y) <= 1, "Signal moved away from anchor: \(signal.frame) vs \(initialAnchor)")
    precondition((signal.contentView as? SignalView)?.ping == .danger)
    RunLoop.current.run(until: Date(timeIntervalSinceNow: (signal.contentView as! SignalView).duration + 0.2))
    precondition(delegate.signal == nil && delegate.animation == nil)
    delegate.showWheel()
    let escapeView = delegate.wheel!.contentView as! WheelView
    let escape = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: delegate.wheel!.windowNumber, context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53)!
    escapeView.keyDown(with: escape)
    precondition(delegate.wheel == nil && delegate.signal == nil)
    delegate.showWheel()
    delegate.showWheel()
    precondition(delegate.wheel == nil)
    delegate.showWheelFromMenu()
    if let screen = NSScreen.main {
        precondition(delegate.anchor == NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY))
    }
    delegate.hideWheel()
    let hook = OptionDrag(owner: delegate)
    delegate.dragHook = hook
    let top = NSScreen.screens.first!.frame.maxY
    let target = NSPoint(x: NSScreen.main!.visibleFrame.midX, y: NSScreen.main!.visibleFrame.midY)
    func mouse(_ type: CGEventType, dx: CGFloat = 0, dy: CGFloat = 0, option: Bool = true) -> CGEvent {
        let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: CGPoint(x: target.x + dx, y: top - target.y - dy), mouseButton: [.rightMouseDown, .rightMouseUp, .rightMouseDragged].contains(type) ? .right : .left)!
        event.flags = option ? .maskAlternate : []
        return event
    }
    precondition(!hook.handle(.leftMouseDown, event: mouse(.leftMouseDown, option: false)))
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(delegate.wheel == nil)
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp)))
    precondition((delegate.signal?.contentView as? SignalView)?.ping == .attention)
    precondition(delegate.wheel == nil && !hook.gesture.ownsMouse)
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: 2 * delegate.wheelScale)))
    precondition(delegate.wheel == nil)
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: 2 * delegate.wheelScale)))
    precondition((delegate.signal?.contentView as? SignalView)?.ping == .attention)
    delegate.animation?.invalidate(); delegate.animation = nil
    delegate.signal?.orderOut(nil); delegate.signal = nil
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: 60 * delegate.wheelScale)))
    precondition(delegate.wheel != nil)
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged)))
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp)))
    precondition(delegate.wheel == nil && delegate.signal == nil)

    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(delegate.wheel == nil)
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: -23 * delegate.wheelScale, dy: 55 * delegate.wheelScale)))
    precondition((delegate.wheel!.contentView as! WheelView).selected == .danger)
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: -23 * delegate.wheelScale, dy: 55 * delegate.wheelScale)))
    precondition((delegate.signal?.contentView as? SignalView)?.ping == .danger)
    delegate.animation?.invalidate(); delegate.animation = nil
    delegate.signal?.orderOut(nil); delegate.signal = nil
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(!hook.handle(.flagsChanged, event: mouse(.mouseMoved, option: false)))
    precondition(delegate.wheel == nil && hook.gesture.ownsMouse)
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: -23 * delegate.wheelScale, dy: 55 * delegate.wheelScale, option: false)))
    precondition(delegate.signal == nil && !hook.gesture.ownsMouse)
    delegate.isPaused = true
    precondition(!hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    delegate.isPaused = false
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    delegate.hideWheel()
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: -23 * delegate.wheelScale, dy: 55 * delegate.wheelScale)))
    precondition(delegate.signal == nil)
    // Far beyond the panel: update by current angle, emit at the original anchor.
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: -2300, dy: 5500)))
    precondition((delegate.wheel?.contentView as? WheelView)?.selected == .danger)
    precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: 2300, dy: 5500)))
    precondition((delegate.wheel?.contentView as? WheelView)?.selected == .attack)
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: 2300, dy: 5500)))
    precondition((delegate.signal?.contentView as? SignalView)?.ping == .attack)
    precondition(abs(delegate.signal!.frame.minX + SignalView.ground.x - target.x) <= 1)
    precondition(abs(delegate.signal!.frame.minY + SignalView.ground.y - target.y) <= 1)
    delegate.animation?.invalidate(); delegate.animation = nil
    delegate.signal?.orderOut(nil); delegate.signal = nil
    for dragged in [false, true] {
        for leftFirst in [false, true] {
            precondition(!hook.handle(.rightMouseDown, event: mouse(.rightMouseDown)))
            precondition(!hook.handle(.rightMouseUp, event: mouse(.rightMouseUp)))
            precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
            if dragged { precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: 3000))) }
            precondition(hook.handle(.rightMouseDown, event: mouse(.rightMouseDown, dx: 3000)))
            precondition(delegate.wheel == nil && delegate.signal == nil)
            precondition(hook.handle(.rightMouseDragged, event: mouse(.rightMouseDragged, dx: 3500)))
            precondition(hook.handle(.leftMouseDragged, event: mouse(.leftMouseDragged, dx: 3500)))
            precondition(delegate.wheel == nil)
            if leftFirst {
                precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: 3500)))
                precondition(hook.handle(.rightMouseUp, event: mouse(.rightMouseUp, dx: 3500)))
            } else {
                precondition(hook.handle(.rightMouseUp, event: mouse(.rightMouseUp, dx: 3500)))
                precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp, dx: 3500)))
            }
            precondition(delegate.signal == nil && !hook.gesture.ownsMouse && !hook.gesture.ownsRightMouse)
            precondition(!hook.handle(.rightMouseDown, event: mouse(.rightMouseDown, option: false)))
            precondition(!hook.handle(.rightMouseUp, event: mouse(.rightMouseUp, option: false)))
        }
    }
    // A missing left-up must not lose ownership of a still-held cancel button.
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(hook.handle(.rightMouseDown, event: mouse(.rightMouseDown)))
    precondition(hook.handle(.leftMouseDown, event: mouse(.leftMouseDown)))
    precondition(hook.handle(.rightMouseUp, event: mouse(.rightMouseUp)))
    delegate.hideWheel()
    precondition(hook.handle(.leftMouseUp, event: mouse(.leftMouseUp)))
    precondition(delegate.signal == nil)
    print("v0.7.1 regressions passed: unbounded drag highlight/send/anchor, right-cancel pending or dragged, both release orders, pass-through and lost-up recovery.")
    for screen in NSScreen.screens {
        for target in [NSPoint(x: screen.frame.minX, y: screen.frame.minY), NSPoint(x: screen.frame.maxX - 1, y: screen.frame.maxY - 1)] {
            delegate.anchor = target
            delegate.emit(.attention)
            let edgeSignal = delegate.signal!
            precondition(abs(edgeSignal.frame.minX + SignalView.ground.x - target.x) <= 1)
            precondition(abs(edgeSignal.frame.minY + SignalView.ground.y - target.y) <= 1)
        }
    }
    let replacingPanel = delegate.signal!
    let replacingTimer = delegate.animation!
    delegate.emit(.heart)
    precondition(!replacingPanel.isVisible && !replacingTimer.isValid)
    precondition((delegate.signal?.contentView as? SignalView)?.ping == .heart)
    delegate.animation?.invalidate(); delegate.animation = nil
    delegate.signal?.orderOut(nil); delegate.signal = nil
    print("Drag handler self-test passed: default click without wheel, drag-return-center cancel, normal click passthrough, drag highlight/send, Option-release cancel, owned mouse-up, pause and timeout cancellation.")
    print("UI self-test passed: panel visibility, first responder, hit testing, number selection, click-through signal, original anchor, animation cleanup, Escape, shortcut toggle.")
}

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--render-preview" {
    do { try renderPreview(to: CommandLine.arguments[2]) } catch { fputs("Preview failed: \(error)\n", stderr); exit(1) }
} else if CommandLine.arguments.contains("--self-test") {
    runUISelfTest()
} else {
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
