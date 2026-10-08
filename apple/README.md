# Lumière uploader apps

Open `LumiereUploader.xcodeproj` in Xcode. It contains two shared schemes:

- **Cogsworth**: macOS 13+, a persistent menu bar app with automatic camera-card uploads.
- **Chip** (Chip by Lumière): iOS/iPadOS 16+, folder selection, file review, album/event/venue entry, progress, cancellation and retry.

Both targets link the local **UploaderCore** Swift package in `../mac/HedonismUploader`. The existing `swift build`/bundle script remains supported. Core includes card scanning, RAW/JPEG grouping, hashing, GraphQL requests, signed storage uploads, progress and a persistent upload ledger. Keychain source is shared by both app targets.

## Server and signing

Run `bin/rails db:migrate` on the server before using these builds. Create a photographer service-account token as described in `../mac/HedonismUploader/README.md`. The default API endpoint is `https://api.lumiere.host/graphql`; the bearer token selects the photographer. Photographer websites and admin pages use `https://<photographer>.lumiere.host`. Custom server URLs remain supported. Tokens are stored in Keychain; they are not embedded in the project.

Choose your development team under Signing & Capabilities for each target before installing on a physical device or distributing. The macOS app runs without the App Sandbox to watch removable volumes and launch the local Python worker. Distribution outside the Mac App Store requires signing/notarization.

Event and venue are free-text shoot details saved as `Album.upload_context` and exposed as `Folder.uploadContext`. They do not create or link canonical Event/Venue records. Album names identify the upload destination within the photographer; use a distinct album name for each shoot. Providing shoot details updates those details on the named album. Existing web clients and unattended date-based uploads remain supported.

## macOS

Settings retain automatic upload, eject-after-success and launch-at-login controls. Cards already mounted at launch are scanned as well as newly inserted cards. The ledger skips completed files across launches; failed files retry on the next upload.

Set **Synology share / DSM URL** to an `smb://host/share` address to open the archive in Finder, or an `https://host:port` DSM address. macOS/Finder manages NAS credentials. **Manage older albums** opens the server's admin page, where an admin can use existing archive/restore controls. Opening a NAS share does not change the server's storage backend or automatically copy/delete originals. Configure the server's archive storage separately before using its archive controls.

For **who_dis**, install `uv`, run `uv sync` in the repository's `who_dis` directory, and configure the absolute directory and `uv` executable paths in Settings. Set Redis to the same broker used by the Rails app. Start/stop the worker from the menu, or enable starting it when the uploader opens. The process receives `GRAPHQL_URL`, `API_KEY` and `REDIS_URL`; its exit status appears in the menu. Worker output goes to the app's standard output/error. The uploader requests worker termination when it quits. Model dependencies/weights are supplied by the existing Python environment, not bundled in the app. Redis is a separate service.

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
