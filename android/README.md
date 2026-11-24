# Chip for Android

Chip by Lumière for Android phones and tablets (Android 8.0+), with the same features as Chip for iOS:

- Sign in with Facebook (Custom Tab + PKCE, returning to `lumiere-uploader://signin`) or a one-use device code, and pick an archive when you administer several. Several accounts can be saved; credentials are encrypted with an Android Keystore key.
- Album, event and venue for each upload.
- Shoot location recording in a foreground service with a notification, sent with uploads (no background-location permission).
- Select an SD card (USB/USB-C reader or the phone's slot) or its DCIM folder through the system folder picker.
- Take photo (system camera) and Photo library (system photo picker, no media permission). Library originals are kept for DNG, ARW, HEIC, JPEG and PNG; other formats are re-encoded as JPEG with their EXIF.
- The same hash-checked upload as iOS and Cogsworth: SHA-256/MD5 every file, skip content the server already has, upload RAW+JPEG shots through photo promises, remember uploads per account, cancel and retry.

Sign in with Apple stays on Apple devices for now: on Android it would need a web Sign in with Apple flow on the server.

## Layout

- `core/`: the upload core in plain Kotlin (scanner, hasher, GraphQL client, sign-in, uploader). It is its own Gradle build that needs only Maven Central, so it builds and tests anywhere: `./gradlew -p core test`.
- `app/`: the Compose app. `./gradlew :app:recordRoborazziDebug` runs the Robolectric tests and records the Play Store screenshots into `store/screenshots/` (phone 1080x1920, 7" and 10" tablets).
- `store/`: Play listing assets and text.

## Release

`app/build.gradle.kts` signs release builds with the upload key named in `android/local.properties` (`chip.upload.*`, or the shared `hotmess.upload.*` keys): `storeFile` (a leading `~` is your home folder), `storePassword`, `keyAlias`, `keyPassword` (defaults to `storePassword`). On the release Mac, link the shared key's file: `ln -s ~/Sites/audience-kit/apps/hot_mess/android/local.properties android/local.properties`. Pass a version code that is higher than anything in Play:

```sh
./gradlew :app:bundleRelease -Pchip.versionCode=$(( $(date -u +%s) - 1767225600 ))
```

CI (`.github/workflows/android.yml`) runs the tests, lint and an unsigned R8 release build, and uploads the screenshots as an artifact.
