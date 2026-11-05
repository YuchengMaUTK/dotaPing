# Third-party asset notice

The public source distribution excludes standalone game resource images, sounds, the derived sound catalog and copied game reference files described below. Documentation images show the app UI with game artwork; that third-party artwork is not covered by the MIT license. Paths in the historical provenance notes refer to optional local imports. MIT applies only to original project work; it does not license Valve content.

## Dota 2 Ping textures

These are Valve Dota 2 game image exports, not artwork created for DotaPing.

- Discovery: https://github.com/S1nuxoff/dota2-files
- Browsable search: https://s1nuxoff.github.io/dota2-files/images/?q=pings%2F
- Download source: https://huggingface.co/datasets/Sqls1/dota2-images/tree/main/panorama/images/pings
- Game filename cross-check: https://github.com/SteamTracking/GameTracking-Dota2/blob/master/game/dota/pak01_dir/scripts/ping_wheel.vdata
- Retrieved 2026-11-04; exact source URLs, byte counts and SHA256 are in ASSET_SOURCES.json.

The source is a third-party community export, not a Valve-hosted asset download. PNG bytes are unmodified; the app scales them and dims/desaturates inactive icons at render time. Images are 128 x 128 with transparency. The original PSD layers are not included.

The orange warning artwork is ping_icon_retreat_psd.png (the game's retreat icon). DotaPing labels this slot CAUTION. ping_danger_psd.png is a silver X, retained as an unused alternate. Other textures match their respective game ping definitions.

Dota 2 and the artwork are copyright Valve Corporation. This local prototype is unofficial and not affiliated with Valve. These files are not covered by any original-code license in this project. Public availability does not establish redistribution rights: do not sell the assets or publish this bundle without checking applicable Valve terms or obtaining permission.

The eight wheel icons and the standard attention icon are game exports. The wheel background also uses exported textures; desktop animation is app code, and sounds use original game exports as of v0.8.


## v0.6 wheel and particle layers

- Additional original wheel images: Sqls1/dota2-images, panorama/images/hud/ping_wheel/large/.
- Original particle sprites: https://huggingface.co/datasets/Sqls1/dota2-particles. Used for beam, ring/wave, arrows, flare and overhead highlight. Source bytes remain unchanged; app applies blue tint and opacity when rendering.
- Additional exact URLs, byte sizes and SHA256 are recorded in V06_ASSET_SOURCES.json.
- CSS/XML reference: https://huggingface.co/datasets/Sqls1/dota2-data/resolve/main/panorama/styles/hud/dota_hud_ping_wheel.css and the corresponding panorama/layout/hud/dota_hud_ping_wheel.xml. Copies are in References/.
- Particle composition reference: particles/ui_mouseactions/ping_world.json and its ground/overhead children in the particle dataset. Source 2 emitters, material blending, dynamic control points, depth and lighting are NOT executed by this app. Desktop composition remains an approximation, not a complete original particle-system port.
- Wheel/cardinal separators and animation transforms remain app code; game-export PNGs do not imply redistribution permission. The Valve rights notice above applies to all additional assets.


## v0.7 per-ping particle artwork

- Additional overhead sprites and highlights are recorded in V07_ASSET_SOURCES.json, with source URL, byte count and SHA256. Original PNG bytes are preserved.
- References/particle-notes.md describes the source particle definitions and chosen desktop approximations. Blue beam, orange caution and beam-free ward behavior were compared with the official Spring Forward 2025 pings.webm video.
- Source 2 materials use additive rendering. The desktop app converts emitted intensity to alpha and tints glow layers at runtime; it does not reproduce game-scene lighting or depth.


## v0.8 original ping audio

- Nine unmodified WAV exports from Sqls1/dota2-sounds, pinned to dataset commit 8b679d5c345d8ab8852735ff5ca4e2f97952cc79. SOUND_SOURCES.json records URLs, SHA256, byte sizes and matching compiled game-resource paths.
- References/ping_wheel.vdata and the sound-event export establish the mapping, voice layers, gain and pitch. These are game assets, not macOS alerts or mixed-audio video captures.
- Public availability does not grant redistribution rights. The Valve rights notice and redistribution caution above apply equally to these sounds. Desktop mixing is implemented independently; Source 2 spatialization and DSP are not reproduced.

## v0.8.2 bronze mastery badge

- V082_ASSET_SOURCES.json pins the unmodified hero_level.png atlas and its frame metadata to a dataset revision. Bronze tier 1 maps to sequence 0 through the overhead renderer's CP3.y remap (1→0). Frame [203,477,187,163] uses top-left coordinates.
- Runtime selects that frame without recolouring, preserving its aspect ratio. It replaces only the unsupported waypoint arrow; no rank medal or drawn substitute is used. The Valve rights notice applies.
