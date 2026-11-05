# Source release validation

Validated locally on Apple Silicon on 2026-11-04:

- Standalone, asset-free CoreChecks package: 27,795 assertions passed.
- Local importer: 57 files checked against SHA256 and size before copying.
- Original image provenance: 45 PNGs and bronze atlas metadata verified.
- Audio provenance: 9 WAVs verified, decoded by macOS tools, with event mappings checked.
- Production app rebuilt from this source using the imported local assets.
- Info.plist validation and strict ad-hoc signature verification passed.
- Original icon dimensions, ICNS structure and packaged branding checks passed.
- Packaged app self-test passed: synthetic gesture regressions, window behavior,
  rendered-pixel checks and all nine audio mappings rendered offline.
- Public-tree scan passed. Game assets, local build outputs and personal macOS
  paths are excluded from the public source distribution.

The local compiler emitted existing missing CLT linker-search-path warnings and
CIColorKernel deprecation warnings; the release build completed successfully.

The macOS GitHub Actions workflow has been prepared but has not run remotely.
Publication and remote CI results are checked separately from these local checks.
No Developer ID signing or notarization was performed.
Synthetic gestures and offline audio do not verify real event delivery in another
application or speaker output. Physical multiple displays, full-screen apps,
VoiceOver, minimum macOS runtime and Intel Macs remain unverified.
