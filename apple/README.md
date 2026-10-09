# Lumière uploader apps

Open `LumiereUploader.xcodeproj` in Xcode. It contains shared schemes for the native companions:

- **Cogsworth**: macOS 14+, a persistent menu bar app with automatic camera-card uploads.
- **ChipMac**: macOS 14+, a sandboxed, upload-only Chip app with manual folder selection and shoot details. No Python, ML services, storage registration, or automatic card watcher.
- **Chip** (Chip by Lumière): iOS/iPadOS 16+, folder selection, file review, album/event/venue entry, progress, cancellation and retry.

All three app targets link the local **UploaderCore** Swift package in `../mac/HedonismUploader`. The existing `swift build`/bundle script remains supported. Core includes card scanning, RAW/JPEG grouping, hashing, GraphQL requests, signed storage uploads, progress and a persistent upload ledger. Keychain source is shared by both app targets.

## Server and signing

Chip opens on a branded sign-in page until an account is saved. Facebook sign-in is the primary action; **or sign in with device code** opens service-account sign-in. Saved accounts bypass the login page on subsequent launches, and **Add account** uses the same flow.

To provision a service-account device, run `bin/rails service_accounts:device_code ID=<existing-service-account-id>` on the server, or POST `/auth/device/code` with that service account's bearer token. Enter the returned code in Chip within ten minutes. Redemption at `/auth/device/exchange` creates a separate device token and consumes the code. Codes cannot be reused; revoked source accounts cannot redeem outstanding codes. Credentials remain in Keychain.

Run `bin/rails db:migrate` on the server before using these builds. Create a photographer service-account token as described in `../mac/HedonismUploader/README.md`. The default API endpoint is `https://api.lumiere.host/graphql`; the bearer token selects the photographer. Photographer websites and admin pages use `https://<photographer>.lumiere.host`. Custom server URLs remain supported. Tokens are stored in Keychain; they are not embedded in the project.

Choose your development team under Signing & Capabilities for each target before installing on a physical device or distributing. The Cogsworth-AppStore configuration uses App Sandbox and two bundled XPC services: a native uploader and an embedded-Python AI service. Use Upload now to grant folder access before automatic card uploads. Distribution outside the Mac App Store requires signing/notarization.

Event and venue are free-text shoot details saved as `Album.upload_context` and exposed as `Folder.uploadContext`. They do not create or link canonical Event/Venue records. Album names identify the upload destination within the photographer; use a distinct album name for each shoot. Providing shoot details updates those details on the named album. Cogsworth uses the standard web upload flow without supplying an album name or prefix. Chip can still supply an explicit album and shoot details.

## macOS

In Cogsworth Settings, enter your photographer subdomain and choose **Sign in via browser**. The existing Facebook browser flow verifies that you administer that photographer, then returns a short-lived PKCE code. Cogsworth exchanges it over HTTPS, validates the photographer, and saves the credential in Keychain. Alternatively, enter a one-use device code issued by `POST /auth/device/code` using an existing service-account bearer token. Codes expire after ten minutes. Settings and the menu display the connected photographer; **Sign out** removes the local credential. Saved credentials are checked on launch.

Settings retain automatic upload, eject-after-success and launch-at-login controls. Cards already mounted at launch are scanned as well as newly inserted cards. Before sending any photo bytes, the uploader hashes every supported card file with SHA-256, checks completed content on the authenticated photographer’s server in batches, and uploads only missing content. Renamed files are recognized by content; files changed without a size or timestamp change are rechecked. Server-confirmed files and duplicate bytes on the card are skipped. A failed preflight stops the run before uploading. Deploy the `/auth/uploaded_contents` endpoint with the client update. Failed files retry on the next upload.

Set **Synology share / DSM URL** to an `smb://host/share` address to open the archive in Finder, or an `https://host:port` DSM address. macOS/Finder manages NAS credentials. **Manage older albums** opens the server's admin page, where an admin can use existing archive/restore controls. Opening a NAS share does not change the server's storage backend or automatically copy/delete originals. Configure the server's archive storage separately before using its archive controls.

Cogsworth includes an isolated ARM64 Python 3.13 runtime and frozen ML dependencies; users do not need Python or `uv`. The service starts after sign-in and connects to `wss://api.lumiere.host/cable` using the selected service-account bearer token. Rails stores durable work and scopes claims to that account’s photographer. Heartbeats renew bounded leases; completion validates the lease before applying results. Signing out stops the AI XPC service. Model weights download on first use into that service’s sandbox container. The menu indicates an authenticated connection, not just a running process. The ML service embeds CPython directly through a native shim; there is no external `uv` or source-directory fallback. The uploader is a separate Swift XPC service. Both use outgoing connections only. Release builds require Apple Silicon and macOS 14 or later.

### Local archive storage

Choose **Connect archive storage…** in Cogsworth to select multiple local or mounted NAS folders. The selection is saved per credential and registered with the photographer’s server. Available folders and the Mac name are refreshed every minute; **Admin → Storage** displays them with online/offline status. Disconnecting a folder removes its registration without deleting files. Apply the `CreateArchiveStorageConnections` migration on the server.

This registers local storage; album archive/restore transfers still use the configured server archive bucket. Local folder transfer support is a separate step.

## iPhone / iPad

Connect a compatible SD card reader. Select either the card root or its DCIM directory through the system folder picker, review supported files, and enter the album, event and venue. Keep the card connected and the app open until uploading finishes. Cancel stops the active operation; press Upload again to retry remaining files. Completed files are remembered locally. Files are uploaded directly from the card without importing into Photos.

This version uses foreground URLSession uploads. It does not promise transfers after iOS suspends/terminates the app, or after the card is removed. Durable background uploads would require staging originals in app storage and a background transfer/finalization queue.

## Validation

```sh
swift test --package-path mac/HedonismUploader
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Cogsworth -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
bundle exec rspec spec/graphql/mutations/create_photo_promise_album_spec.rb spec/graphql/mutations/create_photo_promise_spec.rb spec/graphql/mutations/attach_photo_promise_files_spec.rb spec/graphql/mutations/update_photo_promise_file_update_spec.rb
bundle exec rubocop
```

Physical card access, Synology authentication and a live ML worker require hardware/service integration testing with your environment.

## UI tests on a connected iPhone

`Chip` now includes the `ChipUITests` target in its Test action.
The tests exercise launch, disabled upload before card selection, album/event/venue editing,
and cancellation of the system folder picker. They do not send photos to the live API.
Use Product → Test in Xcode with the connected iPhone selected, or:

```sh
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip \
  -destination 'platform=iOS,id=<device-UDID>' \
  DEVELOPMENT_TEAM=<your-team-ID> -allowProvisioningUpdates test
```

Unlock the phone and enable Developer Mode/trust if iOS requests it. Test screenshots are
saved as attachments in the `.xcresult` bundle. Actual SD-card transfers require a connected
reader/card and a service-account token in the app.

## Saved accounts and Facebook

On iOS, use **Add account**, then either **Continue with Facebook** or **Sign in with token**.
Facebook uses the existing server-side Facebook app registration and OmniAuth credentials;
no Facebook secret is included in the native app. Enter the photographer subdomain you
administer. Add as many photographer accounts as needed, then choose one in **Upload account**
before uploading. Validated credentials remain in Keychain across launches. Metadata and the
last selected account are saved separately; upload history is isolated per saved account.
Signing in again to the same server/photographer updates its credential and preserves history.
**Sign out of selected account** removes that account and its local credential; it does not
log other accounts out or sign the user out of Facebook in other apps.

Deploy the Rails changes and run `bin/rails db:migrate` before using native Facebook sign-in.
The existing Facebook application's allowed web redirect URIs must include
`https://api.lumiere.host/auth/facebook/callback`. This configuration must be made in Meta's
app dashboard if it is not already present. The web login returns a two-minute, single-use
PKCE-bound code to `lumiere-uploader://signin`; the credential is obtained over HTTPS.
Facebook-issued credentials are checked against the user's current photographer permissions
on every authenticated API request. Removed access or pending account deletion invalidates them.
The existing standalone service-account tokens continue to work.

Device UI tests use a separate defaults suite and Debug-only account metadata fixtures to test
selection persistence without real credentials or Facebook interaction. Live Facebook login
requires deployed endpoints, Meta redirect configuration and a human completing Facebook login.

## App Store release preparation

See [Cogsworth's Mac App Store preparation](app-store/COGSWORTH.md) for its release
identity, draft listing and submission blockers. The macOS Xcode target includes
version 1.0.0 (build 1), the Lumière app icon, native required-reason privacy
declarations, folder bookmarks and two bundled XPC services. Distribution-signed
hardware acceptance and the remaining privacy audit are required before submission.

See [Chip's release checklist and draft listing](app-store/README.md) for the
App Store Connect setup, signing, privacy/login review, screenshots and TestFlight
acceptance gates. Chip starts at version 1.0.0 (build 1) and includes a required-reason
API privacy manifest. Submission still requires the gates in that checklist.

## Shoot location recording

Chip's Shoot location section provides Start/Stop recording and deletion of saved phone history. Recording is opt-in, continues while the app is in the background, and stores timestamped coordinates and horizontal accuracy on the phone. After termination, an unfinished session ends at its last saved sample; start a new session when reopening Chip. History is sent with uploads from this phone and retained on the upload promise. Deleting local history does not delete previously uploaded history.

The server matches EXIF DateTimeOriginal plus OffsetTimeOriginal against recording sessions. Keep the camera clock accurate and configured to write its timezone offset. Without that offset, venue inference is skipped. Samples must be within two minutes of capture and have accuracy of 100 metres or better. A venue is inferred only when exactly one configured venue envelope contains the sample; missing or ambiguous coverage stays unresolved. The result is exposed per photo as `inferredVenue`, independently of the album's manual venue text. JPEG/HEIF and RAW metadata are processed.

Deploy migration `20261008230000_add_shoot_location_history` and the updated GraphQL server before using the updated Chip client. On a physical phone, verify permission denial, recording with the screen locked, Stop, reopening, local deletion, and uploads with known capture timestamps before release. The App Store privacy disclosure must include precise location collected for app functionality and linked to the upload account.

## Chip for Mac

Choose the **ChipMac** scheme. It shares Chip's SwiftUI upload/account flow and
`UploaderCore` with iOS, while location recording remains iOS-only. Select a card
or folder, review the files, enter album/event/venue, and upload. Keep Chip running
and the source connected; cancellation and retry use the existing upload ledger.
Chip does not watch cards automatically. When using it alongside Cogsworth,
disable Cogsworth's automatic upload before importing the same card in Chip;
cross-process upload ownership is not yet coordinated.

```sh
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme ChipMac \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

Debug, Release, and AppStore configurations use App Sandbox, outgoing networking,
and read-only user-selected file access. The target embeds no XPC services or
Python runtime. Its bundle identifier matches iOS Chip (`social.hotmess.LumiereMobile`)
for the intended single App Store record; Cogsworth retains its separate identity.
The project configuration does not add macOS to App Store Connect or publish a build.
Before distribution, select the signing team, validate a signed sandboxed build's
browser/device-code login and physical-card upload/cancel/retry, and complete the
macOS listing, screenshots, privacy disclosures, and provisioning. The Mac privacy
manifest excludes mobile location recording; photo/account collection still needs
accurate App Store disclosures.
