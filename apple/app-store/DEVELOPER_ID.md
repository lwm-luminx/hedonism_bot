# Cogsworth: Developer ID distribution

Kickoff: 2026-10-10. Goal: ship Cogsworth outside the Mac App Store as a notarized,
stapled DMG signed with the team's Developer ID, alongside the App Store track in
[COGSWORTH.md](COGSWORTH.md).

## Approach

The Developer ID build reuses the `AppStore` configuration and `Cogsworth-AppStore`
scheme. That configuration already enables Hardened Runtime and App Sandbox on the
app and both XPC services, with the minimal entitlements described in COGSWORTH.md.
Keeping the sandbox for direct distribution means one entitlement set, one smoke test
(`apple/macOS/Tests/verify_entitlements.py`) and the same review of data access for
both channels. Only the export method differs:
[`apple/macOS/ExportOptions-DeveloperID.plist`](../macOS/ExportOptions-DeveloperID.plist)
exports with `developer-id` for team `DWVXMLB45Y`.

No hardened-runtime exceptions are added. The embedded Python framework and its native
libraries are re-signed by Xcode's export with the same Team ID, so library validation
holds. If notarization rejects a nested binary, the script prints Apple's log; fix the
signing of that binary rather than adding `disable-library-validation`.

## Prerequisites (on the release Mac)

- A **Developer ID Application** certificate for team `DWVXMLB45Y` in the login keychain.
  Only the Account Holder can create one. Check with
  `security find-identity -v -p codesigning`.
- An App Store Connect API key with Developer or Admin role. The `.p8` stays in
  `~/.appstoreconnect/private_keys/`; nothing secret is committed.
- Xcode 26 and the bundled Python inputs that `bundle-python.sh` expects.

## Release

```sh
ASC_KEY_ID=<key id> ASC_ISSUER_ID=<issuer id> \
  mac/HedonismUploader/script/release-developer-id.sh 1.0.0 5
```

The script:

1. Archives `Cogsworth-AppStore` with automatic signing, authenticating Xcode with the API key.
2. Exports with the Developer ID options and checks the signature authority, a strict
   nested signature verification and the expected sandbox entitlements.
3. Zips the app, submits it with `notarytool --wait`, staples and runs `spctl`.
4. Builds a compressed DMG with an Applications link, signs it with a secure timestamp,
   notarizes and staples it, assesses it with `spctl`, and prints its SHA-256.

Output lands in `mac/HedonismUploader/.build/developer-id/<version>-<build>/` (ignored by git).
Build numbers are shared with the App Store track, so always use a number higher than
any earlier upload.

## Open decisions

- **Updates.** Direct downloads get no automatic updates. Cogsworth is a menu-bar app
  that talks to a changing server API, so in-app updates are worth adding before a wide
  release. Sparkle 2 works inside the sandbox via its XPC installer services but adds
  an EdDSA signing key and an appcast to host. Not added yet.
- **Download location.** Where the DMG is published (for example the Lumière site or
  GitHub releases) is not decided.
- **Migration.** Users moving between the App Store and direct builds share the bundle
  identifier and sandbox container, so preferences carry over; credentials in the
  Keychain are tied to the signing team and should also carry over. Confirm on a clean Mac.
