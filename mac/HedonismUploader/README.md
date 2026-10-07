# Hedonism Uploader (macOS)

A menu bar app that watches for camera cards (any removable volume with a `DCIM` folder) and uploads
new photos to hedonism_bot as a service account. Files that share a name (`DSC00001.ARW` +
`DSC00001.HIF`) become one photo; photos land in albums named `<prefix> <yyyy-MM-dd>` by the day
they were taken. Already-uploaded files are remembered, so re-inserting a card only sends new shots,
and a file that failed is retried the next time the card goes in.

## Set up

1. Create a token for the photographer on the server (shown once):

   ```sh
   heroku run -a <app> bin/rails service_accounts:create SUBDOMAIN=<photographer> NAME="Rick's Mac"
   ```

2. Build the app (needs Xcode 15+ or the Swift 5.9 toolchain, macOS 13+):

   ```sh
   cd mac/HedonismUploader
   script/bundle-app.sh
   open .build/HedonismUploader.app
   ```

3. Click the SD card icon in the menu bar → Settings…, enter the server URL (the photographer's
   hedonism_bot address) and the token, then Test connection.

Settings also has: album name prefix (default `SD`), upload automatically on insert (default on),
eject when everything uploaded, and open at login. The token is kept in the login keychain and the
upload ledger in `~/Library/Application Support/HedonismUploader/uploaded.json`.

The build is signed ad hoc, so the first launch needs right-click → Open. Revoke a token with
`bin/rails service_accounts:revoke ID=…` (`service_accounts:list` shows them).

## Develop

`swift test` runs the core tests (scanning, ledger, hashing, and the upload flow against an
in-process fake server). CI builds and tests on macOS.
