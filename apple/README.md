# Lumière uploader apps

Open `LumiereUploader.xcodeproj` in Xcode. It contains two shared schemes:

- **LumiereMac**: macOS 13+, a persistent menu bar app with automatic camera-card uploads.
- **LumiereMobile**: iOS/iPadOS 16+, folder selection, file review, album/event/venue entry, progress, cancellation and retry.

Both targets link the local **UploaderCore** Swift package in `../mac/HedonismUploader`. The existing `swift build`/bundle script remains supported. Core includes card scanning, RAW/JPEG grouping, hashing, GraphQL requests, signed storage uploads, progress and a persistent upload ledger. Keychain source is shared by both app targets.

## Server and signing

Run `bin/rails db:migrate` on the server before using these builds. Create a photographer service-account token as described in `../mac/HedonismUploader/README.md`. Configure the photographer's HTTPS server URL and token on each device. Tokens are stored in Keychain; they are not embedded in the project.

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
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme LumiereMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme LumiereMobile -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
bundle exec rspec spec/graphql/mutations/create_photo_promise_album_spec.rb spec/graphql/mutations/create_photo_promise_spec.rb spec/graphql/mutations/attach_photo_promise_files_spec.rb spec/graphql/mutations/update_photo_promise_file_update_spec.rb
bundle exec rubocop
```

Physical card access, Synology authentication and a live ML worker require hardware/service integration testing with your environment.
