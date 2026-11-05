import AppKit

// Original DotaPing artwork. No fonts, logos, downloaded textures or game assets.
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let design = root.appendingPathComponent("Design")
let icons = design.appendingPathComponent("AppIcon.iconset")
let branding = root.appendingPathComponent("Sources/DotaPing/Resources/Branding")
for folder in [design, icons, branding] { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255, blue: CGFloat(hex & 255)/255, alpha: alpha)
}
func polygon(_ vertices: [(CGFloat, CGFloat)]) -> NSBezierPath {
    let p = NSBezierPath(); p.move(to: NSPoint(x: vertices[0].0, y: vertices[0].1))
    for v in vertices.dropFirst() { p.line(to: NSPoint(x: v.0, y: v.1)) }; p.close(); return p
}
func fill(_ path: NSBezierPath, _ hex: UInt32, _ alpha: CGFloat = 1) { color(hex, alpha).setFill(); path.fill() }
func gradient(_ path: NSBezierPath, _ top: UInt32, _ bottom: UInt32) {
    NSGradient(starting: color(bottom), ending: color(top))!.draw(in: path, angle: 90)
}
func stroke(_ path: NSBezierPath, _ hex: UInt32, _ alpha: CGFloat, _ width: CGFloat) {
    color(hex, alpha).setStroke(); path.lineWidth = width; path.stroke()
}
func line(_ points: [(CGFloat, CGFloat)]) -> NSBezierPath {
    let p = NSBezierPath(); p.move(to: NSPoint(x: points[0].0,y: points[0].1))
    for v in points.dropFirst() { p.line(to: NSPoint(x: v.0,y: v.1)) }; return p
}
// Two opposed territories with a broad, angular NW-to-SE river between them.
// Custom shoreline geometry, not a tracing of the Dota logo.
let radiant = polygon([(205,790),(384,655),(400,572),(530,488),(561,390),(794,205),(268,205),(205,268)])
let dire = polygon([(230,819),(756,819),(819,756),(819,230),(655,381),(632,474),(503,556),(465,656)])
// Original simplified ping glyphs, sized for app-icon legibility.
let attentionStem = polygon([(300,432),(354,432),(348,324),(306,324)])
let attentionDot = NSBezierPath(roundedRect: NSRect(x: 303,y: 255,width: 48,height: 48),xRadius:8,yRadius:8)
func sword(angle: CGFloat) -> NSBezierPath {
    let path = polygon([(-18,-102),(18,-102),(18,-62),(42,-62),(42,-39),(19,-39),
                        (19,62),(0,99),(-19,62),(-19,-39),(-42,-39),(-42,-62),(-18,-62)])
    let transform = AffineTransform(translationByX: 693,byY: 694)
    var rotation = AffineTransform(); rotation.rotate(byDegrees: angle)
    path.transform(using: rotation); path.transform(using: transform)
    return path
}
let attackSwords = [sword(angle: -43), sword(angle: 43)]
func pingGlyphs(template: Bool, detailed: Bool) {
    if template {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
        fill(attentionStem,0); fill(attentionDot,0)
        for path in attackSwords { fill(path,0) }
        NSGraphicsContext.restoreGraphicsState()
        return
    }
    for path in [attentionStem,attentionDot] {
        stroke(path,0x243D38,0.9,14)
        fill(path,0xEDF0D5)
    }
    for path in attackSwords {
        stroke(path,0x62392F,0.9,14)
        fill(path,0xFFE4B9)
    }
    if detailed {
        stroke(line([(309,422),(307,337)]),0xFFFFFF,0.55,3)
    }
}
func territory(_ path: NSBezierPath, top: UInt32, bottom: UInt32) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow(); shadow.shadowColor = color(0x0B151B,0.6); shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0,height: -9); shadow.set()
    fill(path,bottom)
    NSGraphicsContext.restoreGraphicsState()
    gradient(path,top,bottom)
}
func mapMark(template: Bool = false, detailed: Bool = true) {
    if template {
        fill(radiant,0); fill(dire,0)
        pingGlyphs(template: true, detailed: false)
        return
    }
    territory(radiant,top:0xB6C0A0,bottom:0x637D6D)
    territory(dire,top:0xD77D60,bottom:0x954A43)
    // Carved banks illuminate the diagonal divide, rather than a separate ping glyph.
    stroke(line([(205,790),(384,655),(400,572),(530,488),(561,390),(794,205)]),0xDDE1BD,0.9,7)
    stroke(line([(230,819),(465,656),(503,556),(632,474),(655,381),(819,230)]),0xFFD1A0,0.8,7)
    if detailed {
        fill(polygon([(205,268),(268,205),(794,205),(561,390),(470,314)]),0x314F49,0.20)
        fill(polygon([(230,819),(756,819),(650,735),(465,656)]),0xFFC58F,0.12)
        stroke(line([(222,508),(293,539),(319,584)]),0x344E46,0.26,4)
        stroke(line([(747,486),(711,556),(734,585)]),0x522E30,0.28,4)
    }
    pingGlyphs(template: false, detailed: detailed)
}
func drawIcon(_ pixels: Int, template: Bool = false) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer { NSGraphicsContext.restoreGraphicsState() }
    let transform = NSAffineTransform(); transform.scale(by: CGFloat(pixels)/1024); transform.concat()
    NSGraphicsContext.current?.imageInterpolation = .high
    if template {
        let t = NSAffineTransform(); t.translateX(by: -154,yBy: -154); t.scale(by: 1.30); t.concat()
        mapMark(template: true)
        return bitmap
    }
    let tile = NSBezierPath(roundedRect: NSRect(x: 64,y: 64,width: 896,height: 896), xRadius: 196,yRadius: 196)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow(); shadow.shadowColor = color(0x10191D,0.32); shadow.shadowBlurRadius = 24; shadow.shadowOffset = NSSize(width: 0,height: -14); shadow.set(); fill(tile,0x18252B)
    NSGraphicsContext.restoreGraphicsState()
    gradient(tile,0x304149,0x172229)
    NSGraphicsContext.saveGraphicsState(); tile.addClip()
    // The river is continuous through the full map; muted blue avoids a neon stripe.
    let river = polygon([(186,830),(230,859),(506,676),(547,576),(674,495),(694,401),(855,223),(809,180),(520,371),(490,465),(361,550),(345,631)])
    gradient(river,0x80AFBA,0x3D778D)
    mapMark(detailed: pixels >= 64)
    if pixels >= 128 {
        NSGraphicsContext.saveGraphicsState()
        let land = NSBezierPath(); land.append(radiant); land.append(dire); land.addClip()
        var seed: UInt64 = 0xD07A
        func random() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1; return CGFloat((seed >> 32) & 65535)/65535 }
        for _ in 0..<12000 {
            let x = 205 + random()*614, y = 205 + random()*614
            color(random() > 0.5 ? 0xF3DFBD : 0x253239,0.025 + random()*0.035).setFill()
            NSRect(x:x,y:y,width:1 + random()*2,height:1 + random()*2).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    NSGraphicsContext.restoreGraphicsState()
    let rim = NSBezierPath(roundedRect: NSRect(x: 66,y: 66,width: 892,height: 892),xRadius:194,yRadius:194)
    stroke(rim,0xCAD5CF,0.15,3)
    return bitmap
}
func save(_ bitmap: NSBitmapImageRep, _ url: URL) throws { try bitmap.representation(using: .png, properties: [:])!.write(to: url) }
for size in [16,32,128,256,512] {
    try save(drawIcon(size),icons.appendingPathComponent("icon_\(size)x\(size).png"))
    try save(drawIcon(size*2),icons.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try save(drawIcon(1024),design.appendingPathComponent("AppIcon.png"))
try save(drawIcon(18,template:true),branding.appendingPathComponent("StatusIcon.png"))
try save(drawIcon(36,template:true),branding.appendingPathComponent("StatusIcon@2x.png"))
print("Generated original app icon, ten ICNS representations and template status icons.")
