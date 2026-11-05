# Publish the macOS source preview

## Repository

Suggested name: `DotaPing`

Description: `Dota-style desktop pings. Native Swift/AppKit menu-bar app. macOS first.`

Suggested topics: `macos`, `swift`, `appkit`, `menu-bar`, `dota2`, `desktop`, `accessibility`.

Create an empty public GitHub repository without generated README/license files.
From this source checkout:

```sh
python3 tools/check-public-tree.py
git add .
git diff --cached --stat
git commit -m "Prepare macOS-first source preview"
git remote add origin <your-github-repository-url>
git push -u origin main
```

Check that the macOS checks workflow passes on GitHub, then tag:

```sh
git tag -a v0.8.5 -m "DotaPing 0.8.5 macOS source preview"
git push origin v0.8.5
```

Create a GitHub Release for this tag with the body in
`docs/RELEASE_NOTES_v0.8.5.md`. Mark it as a pre-release. Do not attach the local
app bundle: it contains Valve resources whose redistribution rights have not
been established. GitHub's generated source archive contains only Git-tracked files.

## Later binary release

Before publishing an installable app, resolve third-party asset redistribution
or replace the resources with distributable originals. Validate actual global
gestures, multiple displays, fullscreen apps and the minimum macOS version.
State the tested architecture explicitly. Developer ID signing and notarization
are recommended for a public macOS binary. Add binary packaging CI only after
its resource and signing inputs are defined.
