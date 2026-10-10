# Cogsworth (macOS)

A menu bar app that watches for camera cards (any removable volume with a `DCIM` folder) and uploads
new photos to Lumière Archive (hedonism_bot) as a service account. Files that share a name (`DSC00001.ARW` +
`DSC00001.HIF`) become one photo. Cogsworth uploads originals through the same photo-promise flow as web `/upload`,
without supplying an album name or prefix; the server chooses the destination. Already-uploaded files are remembered, so re-inserting a card only sends new shots,
and a file that failed is retried the next time the card goes in.

## Set up

1. Create a token for the photographer on the server (shown once):

   ```sh
   heroku run -a <app> bin/rails service_accounts:create SUBDOMAIN=<photographer> NAME="Rick's Mac"
   ```

2. Build the app (needs Xcode, build-time `uv`, and Apple silicon macOS 14+):

   ```sh
   cd mac/HedonismUploader
   COGSWORTH_SIGNING_IDENTITY="Developer ID Application: <name> (<team>)" script/bundle-app.sh
   open .build/Cogsworth.app
   ```

3. Click the SD card icon in the menu bar → Settings…, enter `https://api.lumiere.host` and the token, then Test connection.

Settings also has: upload automatically on insert (default on),
eject when everything uploaded, and open at login. The token is kept in the login keychain and the
upload ledger in the uploader XPC service’s sandbox container. Use **Upload now** to
select a card or photo folder and grant persistent read access before automatic uploads.

Use an available Apple Development or Developer ID identity so the app and Python libraries
share a Team ID under hardened runtime. Local signing is not notarization or store
submission. Revoke a token with
`bin/rails service_accounts:revoke ID=…` (`service_accounts:list` shows them).

## Develop

`swift test` runs the core tests (scanning, ledger, hashing, and the upload flow against an
in-process fake server). CI doesn't build it (macOS runners cost ten times Linux ones):
before merging, run AudienceKit's `scripts/verify-apple.sh uploader` on a Mac, which runs
`swift test` and `script/bundle-app.sh`.

## macOS and iOS Xcode apps

The shared Xcode project lives at `../../apple/LumiereUploader.xcodeproj`.
See `../../apple/README.md` for the iPhone/iPad upload UI, Synology access,
local who_dis worker controls, server migration and signing instructions.

## XPC services

The app embeds `CogsworthUploader.xpc` (Swift upload core) and `CogsworthML.xpc`
(CPython framework and AI dependencies). Both use plain XPC and outgoing networking;
neither exposes a TCP server. The AI runtime is initialized once per service process.
Stopping the session invalidates the connection and terminates that process, including
any native inference threads. The next start launches a fresh service.

`script/bundle-app.sh` uses the Xcode AppStore configuration and signs the two services
and app with `COGSWORTH_SIGNING_IDENTITY`. `swift run` does not package XPC services. Run `swift test` for unit
tests and `COGSWORTH_SIGNING_IDENTITY="<identity>" script/test-xpc.sh /path/to/Cogsworth.app` for the offline signed-bundle
smoke check. The latter uses a disposable copy and does not use saved credentials.
It verifies the signed entitlements, uploads synthetic bytes to an external loopback
fixture, checks duplicate-content handling, and validates embedded Python startup,
single-interpreter enforcement and shutdown. No server entitlement is needed in the
app or its helpers. The local bundler also verifies the effective signed entitlements.
