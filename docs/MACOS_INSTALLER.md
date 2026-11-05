# macOS installer and notarization

The installer places DotaPing.app in /Applications. Open it there and grant Accessibility access; Option gestures enable automatically. The installer does not launch the app or grant permissions.

## One-time account setup

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/enroll/). An ordinary Apple ID alone cannot issue Developer ID certificates.
2. Create **Developer ID Application** and **Developer ID Installer** certificates in your developer account. Import them into the login Keychain on the build Mac, along with their private keys. You can create a certificate signing request using Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority. A downloaded certificate without the matching private key cannot sign.
3. Verify the Application identity with `security find-identity -v -p codesigning`. The Installer certificate should appear in Keychain Access under My Certificates with its private key.
4. Create an app-specific password at [Apple Account](https://account.apple.com/) and configure a local Keychain profile. Use your own Apple ID and Team ID; the command prompts for the password:

```sh
xcrun notarytool store-credentials DotaPing-notary \
  --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID
```

Never commit passwords, private keys, .p12 files or API keys to this repository.

## Build a local preview

Supply the local assets as described in the README, then:

```sh
bash tools/package-macos.sh preview
```

This creates `dist/DotaPing-0.8.5-local-preview.pkg`. It is unsigned and unnotarized, intended for local packaging validation. It is not a public distribution artifact. Do not bypass Gatekeeper to install it.

## Build the signed release

Use the exact certificate names from your Keychain:

```sh
export DOTAPING_APP_IDENTITY='Developer ID Application: YOUR_NAME (YOUR_TEAM_ID)'
export DOTAPING_INSTALLER_IDENTITY='Developer ID Installer: YOUR_NAME (YOUR_TEAM_ID)'
export DOTAPING_NOTARY_PROFILE='DotaPing-notary'
bash tools/package-macos.sh release
```

The script builds the app, signs with Hardened Runtime and a timestamp, creates a signed installer, submits it to Apple, checks for Accepted status, staples the ticket and validates Gatekeeper acceptance. It produces a .pkg and SHA256 checksum in dist. A rejection stops the release; use the submission id in dist/notarization-result.json with `xcrun notarytool log ID --keychain-profile DotaPing-notary` to inspect Apple's findings.

Signed builds use the stable bundle identifier `com.yuchengma.dotaping` (override with DOTAPING_BUNDLE_ID only before the first release, then keep it fixed). Local preview builds retain the existing prototype identifier. Moving from a prototype to the signed app may require re-adding Accessibility permission.

Before uploading the installer to GitHub Releases, resolve the bundled third-party artwork/audio redistribution rights and validate the signed app on a separate Mac, including Accessibility gestures. The public repository excludes those raw assets, and these scripts do not upload installers automatically.

References: [Developer ID](https://developer.apple.com/developer-id/) · [Notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
