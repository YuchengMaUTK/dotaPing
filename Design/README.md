# DotaPing original identity

A top-down two-faction map emblem: sage-green southwest territory and terracotta northeast territory divided by an angular blue river, with an attention-ping exclamation mark on the southwest bank and crossed attack-ping swords on the northeast bank. Custom shoreline geometry on a dark slate tile retains the river composition; simplified original ping glyphs replace the previous diamond strongholds. No Valve logo, game sprite, third-party font or downloaded texture is used in this icon. Existing game-exported ping/audio resources elsewhere in this project remain separately attributed.

- `AppIcon.png`: 1024-pixel master preview with transparent exterior.
- `AppIcon.iconset/`: ten standard macOS PNG slots, 16 through 1024 pixels.
- `AppIcon.icns`: application icon, copied into the app by `build.sh`.
- `../Sources/DotaPing/Resources/Branding/`: monochrome 18-point status icon at 1x/2x; macOS template rendering supplies the appropriate menu-bar colour.
- `../tools/generate-icon.swift`: editable procedural design source. Stone grain is deterministic; tiny icons omit grain and small terrain details.

Regenerate from the repository root on macOS:

```sh
swift tools/generate-icon.swift .
iconutil -c icns Design/AppIcon.iconset -o Design/AppIcon.icns
bash build.sh
python3 tools/verify-icon.py
```

The app remains a menu-bar accessory, so adding a Finder/application icon does not add a persistent Dock item. No system icon-cache reset or permission change is needed by the build. Original artwork is not an assertion of legal clearance for the app name or other bundled assets.
