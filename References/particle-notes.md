# v0.7 ping particle notes

Source: `Sqls1/dota2-particles` decompiled vpcf JSON under `particles/ui_mouseactions/` (URLs and SHA-256 in
`V07_ASSET_SOURCES.json`). `SignalView` is an AppKit composition of the original sprites. It is **not** a Source 2
renderer and is not pixel-exact. Quartz `plusLighter` stands in for `PARTICLE_OUTPUT_BLEND_MODE_ADD`.

## Hierarchy read from JSON

| Ping (app) | Root vpcf | CP5 | Children |
|---|---|---|---|
| attention | ping_world | 0 | elements_mastery, elements_ground, elements_overhead |
| danger (retreat) | ping_retreat | 6 | elements_mastery, elements_ground, **elements_attack** |
| onMyWay | ping_waypoint | 2 | mastery, ground (0.2 s), waypoint_moveto, overhead |
| attack | ping_attack | 5 | mastery, ground (0.2 s), **elements_attack** |
| help | ping_assist | 7 | mastery, ground, overhead |
| defend | ping_defend_new | 8 | mastery, ground, overhead |
| heart | ping_heart | 9 | mastery, ground, overhead |
| enemy/need vision | ping_enemyward / ping_friendlyward | – | **ping_ground_glow + ping_msg_ward_icon only (no beam)** |

- `C_OP_StopAfterCPDuration` = CP2.y × 0.85 (heart × 1.0). The view stops beam emission at that fraction of the lifetime.
- Lifetimes (scripts/ping_wheel.vdata, cross-checked by the parent): 2 s attention/heart, 3 s assist/defend, 5 s waypoint,
  6 s attack/retreat/wards. These are exposed as `SignalView.lifetime(for:)` and the instance `duration`.
- elements_ground: ground_click (particle_ring_wave), player_flareup and player_light (flare_01, 0.2 s), waypoint_solidcircle
  (0.2 s), waypoint_vertical_energy (aircraft_white z-aligned sprite + beam_generic_2 trails, speed −500, max length 350,
  head taper, overbright 3, colour 206/235/255 light, ground glow 77/157/255).
- elements_attack: sword_pillar 0.1 s (beam_generic_7, constant 252/210/84, 0.5 s emission/lifespan), impact_rays 0.2 s
  (particle_cone_variamt_gradient_1, 255/179/86), sword_icon 0.1 s (ping_icon_attack / ping_icon_retreat), sparks 0.3 s (spark_02).
- ping_ground_glow: valkyrie_ring (radius × 1.76, alpha 0.5) plus particle_heroring_6_crisp drawn three times at UV rotation
  0/120/240. Radius scales with normalised age, one particle at a time, re-emitted from 1.05 s.
- ping_msg_ward_icon: glow_04 with black colour scale (shadow), two ping_icon_ward layers tinted by CP colour, then
  ping_icon_ward_highlight additive in 255/109/109 at alpha 0.5, x offset −0.03.
- overhead_icon_core uses particle textures ping_world / ping_assist / ping_defend / ping_heart / ping_icon_retreat. These are
  not the panorama wheel `*_psd` images, so the view uses only the particle sprites.

## Approximations and choices not taken from the data

- Runtime control-point colours (CP7 team/ping colour) are not in the files. Retreat orange and red/green ward colours are matched by eye to `ground-video-frames.jpg`.
- Friendly ward highlight uses a light green instead of the literal 255/109/109, so the green icon does not get a red cast.
- Historical v0.7 waypoint arrow interpretation was incorrect; replaced by the verified bronze mastery badge in v0.8.2.
- The waypoint spinner is three ping_ring arcs rotating on the ground. Spin speed and radius are tuned, not read from the data.
- Ground ellipse squash 0.62, beam height (~250 px), icon height (+100 px), ray/spark counts and timings below 0.1 s
  precision are tuned. They are not decoded curves. Hero-level ground effects and hero portrait overhead variants are omitted.
- Beam ends: the beam layers use a vertical destination-in gradient mask (soft head/tail). The old view drew hard-edged
  rectangles.
- Additive sprites go through intensity→alpha (`Tint.glow`). Icons are drawn untouched (`Tint.original`), so dark outlines
  survive. The greyscale ward icons use `Tint.multiply`, which keeps alpha and dark detail.
- Reduced motion freezes the composition at t = 0.65 s.


## v0.8 corrections (supersede the v0.7 approximations above)

- New contact sheet: `v08-video-timing.jpg`, extracted from official pings.webm at explicit timestamps. At 1.4 s the default has a wide ring; at 2.0–2.3 s the ring is gone but the white symbol and blue energy remain. Attack at 10.5 s has a ring/burst; at 11–13 s the gold icon and blue trails remain without the ring. This is video wall time, not a claim about exact CP2 runtime values.
- `ping_waypoint_solidcircle` initializes field 1 (lifetime) to **1 second**, not the entire ping duration. Ground hierarchy delays it by **0.2 s**. Its alpha knots (normalized age) are (0.205665,1), (0.484637,0.42824), (0.967238,0). These now drive an independent one-shot expanding ring, linearly interpolated rather than Source 2 spline-exact. Removed the invented persistent small circle and three default arrows, which are not present in this video.
- Ward ring alpha knots are (0,0.02424), (0.17646,1), (0.63154,0.27472), (1,0). One-second pulses with 1.05 s restart remain distinct from the ward icon lifetime; the icon stays visible between pulses. Ward-icon fade-in is 0.636085 s from the exported alpha curve.
- Removed the window-wide last-0.7-second opacity fade. Icons own a final 0.2 s fade, using overhead-icon end-cap duration as an approximation. Wards still use the same final fade here, not their exact one-second end-cap simulation.
- Reduced overlapping white cores, narrowed the main core, spread thin blue trails and used a more saturated video-tuned blue (42/116/255). This is runtime tint tuning, not the literal ground-glow constant in the export. Default symbol itself remains white, as in the video; its surrounding energy is blue. Attack retains its original gold sprite.
- Ground hotspot fades by 1.6 s independently. Beam bottom recedes upward after 0.85 s, leaving energy around/above the icon. These are fitted visual envelopes, not values claimed from VPCF. Total per-ping lifetimes remain configured game-definition values; showcase editing/runtime CP values may differ.
- Source 2 lighting, actual emitter simulation, spline tangents, hero portrait/mastery variants and perspective remain out of scope. Original sprite assets alone do not make this renderer pixel-identical.


## v0.8.1 correction (supersedes upward-receding beam approximation)

- v081-beam-frames.jpg crops official pings.webm. Default at 1.7-2.5 s retains a core connected to the ground point. Attack at 11-13 s has a dimming hotspot/core and remaining strands. This does not justify moving the shared lower boundary upward.
- Removed bottom = ground.y + 76 * retreat. Main glow, core and strand domain keep fixed bounds; brightness fades without upward cropping. Default hotspot remains until terminal fade; specialized hotspots fade earlier. Envelopes remain tuned, not native Source 2 simulation.
- Earlier -500 speed interpretation was incomplete: additional C_INIT_VelocityRandom (large positive local z), C_OP_PositionLock and trail-render parameters are present. Motion direction cannot be established from the sphere initializer alone. Existing scrolling strands remain an approximation.
- Native pixel checks measure lower-column alpha after the ring disappears and terminal fade, rather than only checking that the icon remains.

## v0.8.2 fixed bronze mastery badge

- The triangular waypoint marker was misidentified as an arrow. overhead_icon_core explicitly references materials/particle/prime/hero_level.vtex, with CP3.y mapping tier 1 to sequence 0. The atlas metadata gives bronze frame [203,477,187,163] in a 463×656 image. See V082_ASSET_SOURCES.json and hero_level.json.
- ON MY WAY now draws this frame, preserving original colours and aspect ratio. Removed unsupported repeated bobbing and initial vertical hop for this badge. Size, position and fade remain desktop approximations. Other signal icons, ground/beam timing and sound mappings are unchanged.
- Fixed bronze tier is a user-selected simplification. No hero portrait, dynamic tier selection or full Source 2 mastery emitter implementation is claimed.
