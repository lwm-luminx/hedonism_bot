# Chip review access and hardware acceptance

Prepared 2026-10-08 against the current source. These are draft instructions;
the live reviewer login, sample download and device acceptance remain unverified.
See [release status](README.md) for the recorded build 1.0.0 (3) upload. Verify that
the submitted build includes the flows below; source changes do not update an
already uploaded binary.

## Review access gate

Device codes are supported by Chip's first-launch sign-in screen. In the archive's
web admin, **Devices → Generate pairing code** issues a code. In Chip, choose
**or sign in with device code**, enter it, and choose **Sign in with device code**.
Successful exchange saves the resulting account credential in Keychain.

However, `DeviceLoginGrant` expires codes after ten minutes and destroys each grant
after successful exchange. A code in App Store Connect is therefore not durable
review access. Reinstalling, signing out, or testing another device may require a
fresh code. The web generator currently requires an authenticated archive admin.
The current Chip sign-in UI offers Facebook and device code; the old release notes'
token-entry instructions no longer describe that UI.

Before submission, supply a dedicated, isolated review archive and a repeatable
reviewer login that can generate fresh codes without assistance, or implement and
validate a suitable demo-account flow. Verify access from a clean browser and a
fresh app installation, including a second device and repeated sign-in. Do not
relax production device-code expiry or make production codes reusable for review.
Store credentials in App Store Connect's private review fields, not this repository.

## Reviewer procedure draft

Complete the access gate and provide a reachable sample ZIP download before using
these steps in App Store Connect. Supply the actual review archive URL and access
instructions privately. Do not describe them as available until tested.

1. Download and extract the supplied sample ZIP in Files. It should contain a
   `Chip Review/DCIM/100REVIEW` folder with two small, distinct, valid JPEG images
   that we own or have permission to distribute. Make the folder available offline.
   Record the expected filenames and count with the download.
2. Use the supplied web review login, open **Devices**, and select **Generate
   pairing code**. In Chip choose **or sign in with device code**, paste the code
   and choose **Sign in with device code** within ten minutes. Generate a new code
   if it expires or has already been used. Leave **Server** at its default unless
   the supplied review instructions explicitly identify another deployment.
3. Confirm the review archive appears under **Upload account**. Enter a unique
   **Album**, such as `App Review — <date/time>`, plus **Event** and **Venue**.
4. Choose **Select card / DCIM folder**. In the system picker select the extracted
   `DCIM` folder, then confirm the expected files appear under **Files on card**.
   An ordinary local folder works; a physical camera card is optional for this path.
5. Choose **Upload new files**. Keep Chip open and the source available until it
   finishes. Confirm success in Chip and verify the files in the review archive.
6. Repeat with the same folder and account. Confirm completed files are skipped.
   To test a fresh upload, provide genuinely different image bytes; changing only
   the album name may not bypass deduplication.
7. Quit and reopen Chip; verify the account remains selected. Test **Add account**
   and **Sign out of selected account** using fresh codes when necessary. Signing
   out removes local access; it does not delete the server account or uploaded photos.
8. Location recording is optional: test **Start recording location**, permission
   denial, granting permission, **Stop recording location**, and **Delete saved
   location history**. Uploads should remain usable with location denied. Local
   history deletion does not remove history already sent with previous uploads.

## Simulator, reader and hub setup

- Simulator does not provide a supported SD-reader/USB-storage passthrough test.
  Use sample files in a folder accessible to its Files picker to exercise software
  behavior. Copying samples is not evidence of physical-card support.
- For card acceptance, pair a physical iPhone/iPad with Xcode, enable Developer
  Mode and trust as requested, then confirm Xcode can run on it over the same Wi-Fi
  network with the USB cable disconnected. Attach the reader to the phone/tablet
  and confirm its volume appears in Files before opening Chip's picker.
- For USB-C devices, a compatible powered hub can connect the reader and supply
  charging power. An ordinary hub does not provide simultaneous Mac-to-phone USB
  debugging while the phone acts as the storage host; use wireless Xcode for that
  setup. A hub's power-delivery port is not a second upstream data connection.
- For Lightning devices, use a compatible reader/adapter with adequate external
  power where needed. Confirm the exact device/adapter combination on hardware.
- Apple documents a single data partition and supported filesystems including
  exFAT and FAT32. Verify the card format; do not reformat a user's camera card
  as part of testing.

Run existing UI tests with the paired device selected in Xcode, or:

```sh
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Chip \
  -destination 'platform=iOS,id=<paired-device-UDID>' \
  -resultBundlePath /tmp/Chip-card-ui-tests.xcresult \
  DEVELOPMENT_TEAM=<team-ID> test
```

Use a new result path for each run. Current automated tests cover sign-in controls,
account fixtures, metadata fields and folder-picker cancellation. They do not
authenticate with a real device code, select a physical card or complete an upload.
Perform the following acceptance checks separately on both iPhone and iPad.

| Check | Required evidence | Status |
| --- | --- | --- |
| Fresh code, consumed code, expired code | Success followed by recoverable errors; retry with new code | Pending |
| Sample folder upload without a reader | File list, completed upload, server-side result | Pending |
| Physical card upload | Device/OS, adapter, card format, counts and server-side result | Pending |
| Cancel and retry | Partial progress retained; remaining files complete | Pending |
| Reader disconnect during upload | Recoverable failure; reconnect/reselect and retry | Pending |
| Network interruption | Recoverable failure; retry without duplicate completed uploads | Pending |
| Location denied, allowed and background recording | Permission behavior, stop and local deletion | Pending |
| Relaunch and second-device login | Persisted account; newly generated code works independently | Pending |

Record the tested build, device model, OS, reader/hub and date with results. Capture
an external-camera video of Chip running on a physical device with the reader,
including selection and upload; redact credentials. Apple requests a physical-device
video rather than a screen recording for apps requiring hardware. Include this
evidence for the advertised card workflow even though folder testing is available.

## Remaining submission work

Resolve durable review access; publish and validate sample assets; complete the
acceptance table; capture store screenshots; verify privacy/support URLs, account
deletion, login guideline 4.8 and current privacy disclosures (including location).
Device codes alone do not establish an exception to Apple's login requirements.
Keep the review backend and account available throughout review. No review
submission or credential provisioning is performed by this document.

## References

- [Apple: complete review information](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review)
- [Apple: wireless Xcode devices](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)
- [Apple: iPhone external storage](https://support.apple.com/guide/iphone/external-storage-devices-iph95baac91f/ios)
- [Apple: Simulator differences](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/TestingontheiOSSimulator/TestingontheiOSSimulator.html)
