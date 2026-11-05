# Contributing

DotaPing is macOS first. Focus changes on reliable desktop gestures, rendering,
audio, accessibility and clear macOS setup. Discuss larger platform ports in an issue first.

Run `swift run --package-path CoreChecks PingCoreChecks` and
`python3 tools/check-public-tree.py` before submitting a change.
For app changes, import authorized assets and run the full README checks.
Describe which macOS version, architecture and display arrangement you tested.
Synthetic events do not replace testing gestures in another app.

Do not commit game assets, copied game files, binaries, personal paths, credentials
or Accessibility permission databases. New assets need documented origins and licensing.
Use a small, focused pull request explaining the visible behavior and validation.
