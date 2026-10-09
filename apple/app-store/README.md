# Chip by Lumière: App Store release

Current review preparation: [reviewer access, folder testing and physical-card
acceptance](CHIP-REVIEW.md). Device codes currently expire after ten minutes and
work once; a static code in review notes is not sufficient reviewer access.
Historical setup entries below are superseded by later dated status entries.

Kickoff audit: 2026-10-08. Target: public iOS/iPadOS release, preceded by TestFlight.
This is preparation work; no build has been uploaded or submitted for review.

## Release identity

- Name: Chip by Lumière
- Bundle ID: `social.hotmess.LumiereMobile` (preserves the existing project identity)
- Suggested SKU: `social.hotmess.LumiereMobile`
- Primary locale: en-US
- Initial version: 1.0.0, build 1; increment the build number for each upload.
- Suggested category: Photo & Video
- Suggested release mode: manual, so approval does not immediately publish the app.

The connected App Store Connect account contained four apps at kickoff, with no Chip
record. A filtered bundle-ID lookup also returned no registration for the identifier
above. The available connector exposes neither app creation nor bundle registration;
create these in Apple's developer portal and App Store Connect, checking the owning
team before registration. Configure that team's signing in Xcode.

## Submission gates, in order

1. Register the bundle ID and create the app record; choose pricing, territories,
   content rights and the current age-rating questionnaire based on the actual service.
2. Supply an approved opaque 1024×1024 app icon in an asset catalog and wire AppIcon
   into the Chip target. The project currently has no icon assets.
3. Resolve login guideline 4.8: Chip offers Facebook authentication and a service
   token. A token field does not establish an equivalent privacy-preserving login.
   Implement a qualifying alternative (typically Sign in with Apple) or establish
   that a documented exception applies to this existing-account service client.
   Do not assume Apple will accept an exception.
4. Finish privacy and support publication. `docs/privacy-launch.md` identifies
   draft policy/contact and deployment gaps. Verify public HTTPS URLs without login;
   include links in the app. Review whether account creation is available through
   authentication and provide in-app initiation of account deletion where required.
   Signing out only removes local credentials and does not delete a server account.
5. Audit App Privacy answers against the deployed service, including uploaded photos,
   metadata, photographer identity, Facebook data, retention, and any face processing.
   Do not claim “Data Not Collected” for a photo-upload service. The bundled manifest
   declares required-reason APIs only; it is not a completed data-collection disclosure.
6. Deploy and validate native sign-in endpoints, database migrations, and Meta's
   `https://api.lumiere.host/auth/facebook/callback` configuration. Exercise expired
   credentials, revoked access, upload failures, cancellation and retry on real hardware.
7. Provide a dedicated review account/token through App Store Connect review details,
   never through committed files. Include usable sample images/folders and instructions
   that let review exercise uploads without owning a camera card. Check this workflow
   on iPhone and iPad. Keep the review backend reachable throughout review.
8. Capture actual iPhone/iPad screenshots for the display classes required by App Store
   Connect. Use synthetic or consented photos without production credentials or personal
   information. Do not market background uploads: transfers currently require the app
   to stay open and the card to stay connected.
9. Archive with distribution signing, validate in Organizer, upload to TestFlight,
   complete export-compliance answers based on the actual cryptography, then run a
   hardware acceptance pass before selecting the build for App Review.

## Privacy manifest rationale

`iOS/PrivacyInfo.xcprivacy` is copied into Chip's resources:

- UserDefaults / CA92.1: app-local account metadata, selection and preferences.
- FileTimestamp / 3B52.1: metadata of files in the folder explicitly selected by the
  user through the system picker, used to order photos and identify completed uploads.

Review these declarations whenever file access or defaults storage changes. Backend
collection and processing still need separate disclosure review before submission.

## Build and test

Xcode 27.0 (27A266a) was detected at kickoff. Apple's current minimum upload requirement
is Xcode 26 with the iOS/iPadOS 26 SDK, effective April 28, 2026.

```sh
swift test --package-path mac/HedonismUploader
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip \
  -configuration Release -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip \
  -destination 'platform=iOS,id=<device-UDID>' \
  DEVELOPMENT_TEAM=<team-ID> -allowProvisioningUpdates test
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/Chip.xcarchive DEVELOPMENT_TEAM=<team-ID> archive
```

An unsigned simulator build establishes compilation, not App Store validation.
Do not commit signing secrets, review credentials, archives or derived data.

## Draft English listing

Subtitle: Camera card photo uploads

Description:

Upload camera photos to your Lumière photographer account from your iPhone or iPad.
Connect a compatible card reader, select the card's DCIM folder, review supported
files, and choose the album for your shoot. Add event and venue details, follow
upload progress, and retry remaining files when a transfer fails.

Save multiple photographer accounts and select the destination before each upload.
Photos transfer directly from the selected folder without importing into Photos.

A Lumière photographer account and a compatible photo source are required. Keep
Chip open and your card connected until the upload finishes.

Keywords: photography,camera,SD card,upload,albums,RAW

Before saving the listing: verify supported hardware/file formats, final URLs,
review contact, copyright ownership, pricing and availability. No placeholders should
be copied into live App Store fields.

## Apple references

- [SDK upload requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)
- [Review preparation](https://developer.apple.com/app-store/review/)

## TestFlight setup status — 2026-10-08

- Current project: version 1.0.0, build 2, with AppIcon assets present.
- Local Apple Distribution identity is available for team `DWVXMLB45Y`.
- Signed arm64 device archive succeeded at `/tmp/Chip-TestFlight.xcarchive`.
  This archive is development-signed; App Store export must re-sign it for distribution.
- Added explicit iPhone/iPad supported orientations to resolve the archive warning.
- App Store export was attempted but failed with `No Accounts` and no iOS App Store
  provisioning profile for `social.hotmess.LumiereMobile`.
- A fresh connector check still found no app record or registered bundle ID.
- App Store Connect is open in Chrome awaiting Apple Account sign-in. Once signed in,
  register the explicit bundle ID and create the iOS app using the identity above,
  then configure TestFlight beta information and a private beta group.
- Add the owning Apple Account to Xcode Settings → Accounts (or supply an authorized
  provisioning workflow) and obtain an App Store distribution profile before export/upload.
- No TestFlight build was uploaded, no testers were invited, and no beta review was submitted.

## App record and provisioning completed — 2026-10-08

- Created **Chip by Lumière**, App Store Connect ID `6820711553`, iOS, en-US,
  SKU and bundle ID `social.hotmess.LumiereMobile`.
- Registered the explicit bundle ID under team `DWVXMLB45Y`.
- Created **Chip Internal Testing**, group ID `e0e5792b-6a8c-4348-ad52-e3b8cd8aa10d`.
  Automatic distribution is disabled; no testers have been invited and no public link is enabled.
- Saved the English TestFlight beta description and `https://lumiere.host` marketing URL.
  Feedback email, privacy policy URL, review contact and demo credentials remain to be completed
  with verified details before external testing.
- Generated **Chip App Store Connect**, profile ID `37S63D6TLW`, UUID
  `46e3fb25-b08c-4b41-a6e8-4e6cb43664c9`, expiring 2027-09-02, using the existing
  Apple Distribution certificate. Installed it in Xcode's local profile directory.
- Exported version 1.0.0/build 2 successfully for App Store Connect at
  `/tmp/Chip-TestFlight-export` using manual distribution signing. The directory contains
  the IPA, export options and distribution summary; these temporary artifacts are not committed.
- TestFlight writes via the connected API key returned HTTP 403; browser setup succeeded.
- Upload still requires an authenticated Xcode or Transporter session. No build is uploaded,
  no beta review is submitted, and the public App Store release is not submitted.

[Open Chip in App Store Connect](https://appstoreconnect.apple.com/apps/6820711553/distribution)

## App Store icon

The active AppIcon image is `iOS/Assets.xcassets/AppIcon.appiconset/Chip-AppStore.png`:
1024×1024, RGB/sRGB PNG, with no alpha channel or pre-rounded corners. It preserves
Lumière's seven-blade gold aperture, with a larger silhouette, clearer blade edges
and reduced texture for readability at home-screen sizes. The original `AppIcon.png`
is retained for comparison. The editable master is `brand/masters/chip-app-store.svg`.

Regenerate with `sh brand/render-chip-app-store-icon.sh` (requires `rsvg-convert` and
ImageMagick). This directly adapts the existing vector brand; no image-generation
model or prompt was used. The signed archive and App Store export were rebuilt with
this asset. App Store Connect obtains the iOS icon from an uploaded build; it remains
pending until that upload completes.

## Upload attempt — 2026-10-08

Created upload record `cce2722b-cc3a-4fab-a93b-125b96b3f76d` for 1.0.0 (2).
The connector's file upload failed before transfer with HTTP 409: Apple rejected its
`sourceFileChecksums` SHA_256 value. Xcode's direct upload fallback failed with
`Failed to Use Accounts`: authenticated App Store Connect access for `DWVXMLB45Y`
is required. Xcode UI also displays its first-launch “Install Required” component
prompt. Complete that setup and sign in to the owning Apple Account in Xcode
Settings → Accounts, then retry using `/tmp/Chip-TestFlight-UploadOptions.plist`.
The upload record alone is not a delivered or processed TestFlight build.

## Successful upload — 2026-10-08

Apple confirmed **1.0.0 (3)** uploaded at approximately 4:01 PM America/Denver.
Xcode reported `Upload succeeded` and `Uploaded package is processing`.

Build 2 was rejected for a bundle-signature problem. Its Unicode internal product
filename produced an exported IPA that failed the strict sealed-resource check.
The project now uses the internal filename `Chip.app` and build number 3, while
`CFBundleDisplayName` remains **Chip by Lumière**. Build 3's exported IPA passed
`codesign --verify --deep --strict` with the Apple Distribution certificate.

Archive: `/tmp/Chip-TestFlight-v3.xcarchive`; package: `/tmp/Chip-TestFlight-v3-export/Chip.ipa`.
Upload log: `/tmp/chip-testflight-v3-upload.log`. The earlier connector upload record
for build 2 is not the successful delivery; build 3 was uploaded through Xcode.

Apple processing completed: build ID `da58396c-9b16-479e-a440-f134afdc369e`,
processing state `VALID`. The user explicitly approved the “None of the algorithms
mentioned above” export-compliance answer after review of Apple-provided HTTPS,
Keychain and SHA-256 APIs; that answer was saved in App Store Connect.
