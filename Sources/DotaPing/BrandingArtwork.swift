import AppKit

/// Original app identity, separate from Valve's game-exported ping textures.
enum BrandingArtwork {
    static let statusIcon: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        for name in ["StatusIcon", "StatusIcon@2x"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Branding"),
                  let data = try? Data(contentsOf: url), let rep = NSBitmapImageRep(data: data) else {
                fatalError("Missing original status icon: \(name)")
            }
            rep.size = NSSize(width: 18, height: 18)
            image.addRepresentation(rep)
        }
        image.isTemplate = true
        image.accessibilityDescription = "DotaPing"
        return image
    }()
}
