# Cogsworth: Developer ID distribution

Kickoff: 2026-10-10. Goal: ship Cogsworth outside the Mac App Store as a notarized,
stapled DMG signed with the team's Developer ID, alongside the App Store track in
[COGSWORTH.md](COGSWORTH.md).

## Approach

The `DeveloperID` build configuration and `Cogsworth-DeveloperID` scheme match `AppStore`
(Hardened Runtime, App Sandbox, the minimal entitlements in COGSWORTH.md) with two
additions for [Sparkle](https://sparkle-project.org) updates:

- `mac/HedonismUploader/script/embed-sparkle.sh` downloads the pinned Sparkle release,
  checks its SHA-256 and embeds `Sparkle.framework`. The build phase exits immediately
  for every other configuration, so the App Store build never contains Sparkle.
- [`macOS/Cogsworth-DeveloperID.entitlements`](../macOS/Cogsworth-DeveloperID.entitlements)
  adds only the two Mach services Sparkle's sandboxed installer uses
  (`<bundle id>-spks`, `<bundle id>-spki`).
  [`macOS/Cogsworth-DeveloperID-Info.plist`](../macOS/Cogsworth-DeveloperID-Info.plist)
  sets the feed URL, the EdDSA public key and the installer launcher service.

Swift code guarded by `#if SPARKLE` (`SoftwareUpdater.swift`) adds a "Check for updates"
row to the menu; Sparkle also checks daily on its own. `verify_entitlements.py --developer-id`
checks the extra entitlement and that Sparkle is present, and the default mode fails if
Sparkle ever reaches the App Store build.
[`apple/macOS/ExportOptions-DeveloperID.plist`](../macOS/ExportOptions-DeveloperID.plist)
exports with `developer-id` for team `DWVXMLB45Y`.

No hardened-runtime exceptions are added. The embedded Python framework, its native
libraries and Sparkle are re-signed by Xcode's export with the same Team ID, so library
validation holds. If notarization rejects a nested binary, the script prints Apple's log;
fix the signing of that binary rather than adding `disable-library-validation`.

## Updates and hosting

Releases are published on [GitHub releases](https://github.com/lwm-luminx/hedonism_bot/releases)
with tags `cogsworth-v<version>-<build>`. Each release carries the DMG and an `appcast.xml`
listing only that build. The app reads
`https://github.com/lwm-luminx/hedonism_bot/releases/latest/download/appcast.xml`, so the
newest Cogsworth release must stay marked as the repository's latest release.

Sparkle verifies every update with an EdDSA signature. The private key lives only in the
release Mac's login Keychain (account `lumiere-cogsworth`); back it up with
`generate_keys --account lumiere-cogsworth -x <file>` into a password manager. Losing it
means existing installs cannot accept future updates. Build 5 (1.0.0) predates Sparkle,
so its users install the first Sparkle build by hand once.

## Prerequisites (on the release Mac)

- A **Developer ID Application** certificate for team `DWVXMLB45Y` in the login keychain.
  Only the Account Holder can create one. Check with
  `security find-identity -v -p codesigning`.
- An App Store Connect API key with Developer or Admin role. The `.p8` stays in
  `~/.appstoreconnect/private_keys/`; nothing secret is committed.
- Xcode 26 and the bundled Python inputs that `bundle-python.sh` expects.
- Sparkle 2.10.0's tools in `~/Developer/Sparkle-tools/2.10.0` (or `SPARKLE_BIN`) and the
  EdDSA key in the login Keychain. Publishing also needs the `gh` CLI signed in.

## Release

```sh
ASC_KEY_ID=<key id> ASC_ISSUER_ID=<issuer id> COGSWORTH_PUBLISH=1 \
  mac/HedonismUploader/script/release-developer-id.sh 1.0.1 6
```

The script:

1. Archives `Cogsworth-DeveloperID` with automatic signing, authenticating Xcode with the API key.
2. Exports with the Developer ID options and checks the signature authority, a strict
   nested signature verification and the expected sandbox entitlements.
3. Zips the app, submits it with `notarytool --wait`, staples and runs `spctl`.
4. Builds a compressed DMG with an Applications link, signs it with a secure timestamp,
   notarizes and staples it, assesses it with `spctl`, and prints its SHA-256.
5. Signs the DMG with `sign_update` and writes `appcast.xml`. With `COGSWORTH_PUBLISH=1`
   it creates the GitHub release from the current commit with both files, marked latest.

Output lands in `mac/HedonismUploader/.build/developer-id/<version>-<build>/` (ignored by git).
Build numbers are shared with the App Store track, so always use a number higher than
any earlier upload.

## Open decisions

- **DMG size.** The DMG is about 590 MB, mostly the bundled Python, PyTorch and OpenCV in
  the ML service. Sparkle downloads the whole DMG for each update.
- **Migration.** Users moving between the App Store and direct builds share the bundle
  identifier and sandbox container, so preferences carry over; credentials in the
  Keychain are tied to the signing team and should also carry over. Confirm on a clean Mac.
