import AppKit
import CoreImage
import PingCore

/// Valve game textures from the Sqls1/dota2-images community export.
/// See ASSET_SOURCES.json and THIRD_PARTY_ASSETS.md for provenance.
enum PingArtwork {
    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
    }
    static func polygon(_ points: [(CGFloat, CGFloat)]) -> NSBezierPath {
        let p = NSBezierPath()
        if let first = points.first { p.move(to: NSPoint(x: first.0, y: first.1)) }
        for point in points.dropFirst() { p.line(to: NSPoint(x: point.0, y: point.1)) }
        p.close(); return p
    }
    static let filenames: [Ping: String] = [
        .attention: "ping_world_psd", .danger: "ping_icon_retreat_psd",
        .onMyWay: "ping_icon_waypoint_psd", .defend: "ping_defend_psd",
        .attack: "ping_icon_attack_psd", .enemyVision: "ping_icon_enemyward_psd",
        .needVision: "ping_icon_friendlyward_psd", .help: "ping_assist_psd", .heart: "ping_heart_psd"
    ]
    static let images: [Ping: NSImage] = {
        var result: [Ping: NSImage] = [:]
        for ping in Ping.allCases {
            guard let filename = filenames[ping],
                  let url = Bundle.module.url(forResource: filename, withExtension: "png", subdirectory: "Pings"),
                  let image = NSImage(contentsOf: url), image.isValid else {
                fatalError("Missing or invalid bundled Ping texture: \(ping)")
            }
            result[ping] = image
        }
        return result
    }()
    static let inactiveImages: [Ping: NSImage] = images.mapValues { image in
        guard let data = image.tiffRepresentation, let input = CIImage(data: data),
              let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(0.7, forKey: kCIInputSaturationKey)
        filter.setValue(0.0, forKey: kCIInputBrightnessKey)
        guard let output = filter.outputImage,
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return image }
        return NSImage(cgImage: cgImage, size: image.size)
    }
    static func draw(_ ping: Ping, center: NSPoint, size: CGFloat, active: Bool = true) {
        guard let image = (active ? images : inactiveImages)[ping] else { return }
        let ratio = image.size.width / image.size.height
        let width = ratio >= 1 ? size : size * ratio
        let height = ratio >= 1 ? size / ratio : size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: center.x-width/2, y: center.y-height/2, width: width, height: height), from: .zero, operation: .sourceOver, fraction: active ? 1 : 0.5)
        NSGraphicsContext.restoreGraphicsState()
    }
}

/// Unmodified game-export wheel layers, including transparent padding.
enum WheelArtwork {
    static let names = ["background_bottomlayer", "background", "backlines", "edge", "middlebutton", "middlebutton_pressed", "x", "slicethin_hover"]
    static let images: [String: NSImage] = Dictionary(uniqueKeysWithValues: names.map { name in
        let url = Bundle.module.url(forResource: "minimap_wheel_" + name + "_png", withExtension: "png", subdirectory: "Wheel")!
        return (name, NSImage(contentsOf: url)!)
    })
    static func draw(_ name: String, center: NSPoint, opacity: CGFloat = 1, rotation: CGFloat = 0) {
        NSGraphicsContext.saveGraphicsState()
        let t = NSAffineTransform(); t.translateX(by: center.x, yBy: center.y); t.rotate(byDegrees: rotation); t.concat()
        images[name]!.draw(in: NSRect(x: -100, y: -100, width: 200, height: 200), from: .zero, operation: .sourceOver, fraction: opacity)
        NSGraphicsContext.restoreGraphicsState()
    }
}
