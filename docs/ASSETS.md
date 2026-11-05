# Local asset requirements

The public repository ships original source and branding, but excludes Valve images,
WAVs, the derived game sound catalog and copied game reference files.
Public mirrors and provenance hashes do not establish redistribution permission.
Use assets only where you have the applicable rights; this project grants none.

`tools/import-assets.py --source /absolute/path/to/DotaPing` accepts an existing
project layout. It requires all 45 PNGs and 9 WAVs described by the five source
manifests, plus:

- `Sources/DotaPing/Resources/Sounds/sound_events.json`
- `References/hero_level.json`
- `References/ping_wheel.vdata`

All entries are validated before copying. Existing destination files must match.
The imported folders and reference files are ignored by Git. Their URLs remain
in the provenance manifests for audit, rather than an automatic download step.

Before distributing an app containing these resources, establish redistribution
rights for every included third-party resource. A source release does not establish
permission to distribute the existing local app bundle.
