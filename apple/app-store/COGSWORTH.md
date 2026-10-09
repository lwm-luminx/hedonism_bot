# Cogsworth: Mac App Store preparation

Kickoff: 2026-10-08. Status: bundle identity corrected to `host.lumiere.Cogsworth`. Build 4 was uploaded successfully to the correct app record and is processing in App Store Connect. Earlier build 3 was delivered to the wrong app record (`social.hotmess.LumiereMac`).

## Release identity

| Field | Value |
| --- | --- |
| Name | Cogsworth |
| Bundle identifier | `host.lumiere.Cogsworth` |
| SKU | `lumiere-cogsworth` |
| Version / build | 1.0.0 / 4 |
| Platform | macOS 14+, Apple silicon |
| Category | Photography |
| Suggested locale / release | en-US / manual release |

The Xcode target includes the Lumière icon, version/build metadata, category and
required-reason declarations for preferences and user-granted file timestamps.

Correct App Store Connect record: **Cogsworth by Lumiere**, app ID `6820789559`,
verified against bundle ID `host.lumiere.Cogsworth`.

## Implemented XPC split

- `CogsworthUploader.xpc`: native Swift scanning, hashing, upload progress, cancellation
  and retry through `UploaderCore`. It receives an implicit security-scoped bookmark
  and credentials per upload, and keeps its ledger in its own sandbox container.
- `CogsworthML.xpc`: one isolated embedded CPython 3.13 runtime per service process.
  A native C shim initializes Python; typed `NSXPCConnection` protocols carry startup,
  status and shutdown. The worker retains its outgoing Action Cable connection.
- Both services are embedded by Xcode and linked through `CogsworthIPC`. Only the ML
  target links `Python.framework`. Neither has a network server entitlement, gRPC,
  shared Keychain group or App Group. Credentials stay in the app's Keychain and are
  passed over XPC for the current session.
- Upload now selects a card or ordinary photo folder and saves an app-scoped bookmark.
  Automatic card detection only scans previously authorized cards. Existing archive
  folders need re-selection to establish bookmarks. Unreadable folders return an
  error rather than a successful empty upload.
- The old external `uv`/Python process launcher and developer-path settings are removed
  from the app. `script/bundle-app.sh` now builds through Xcode so local bundles include
  both services. SwiftPM remains the unit-test path, not the app-packaging path.
- The Python packaging step builds from the frozen dependency lock, places the standard
  library and dependencies in a versioned framework, fixes the interpreter install
  name, rejects known build-machine library paths and signs native dependencies before
  their framework. Static development archives are omitted so Xcode embedding does
  not invalidate the resource seal. No interpreter executable is needed by the host.

The previously used, incorrect App Store Connect record is **Cogsworth by Lumière**, app ID `6820751783`,
bundle ID `social.hotmess.LumiereMac`, under team `DWVXMLB45Y`.
The user authorized a TestFlight upload on 2026-10-08. Distribution provisioning
succeeded. The first upload validation found unsandboxed PyTorch utilities; the
packaging fix removes unused `protoc` compilers and signs `torch_shm_manager` with
App Sandbox plus inheritance. This utility is required by PyTorch's import path;
it is not another XPC worker and gains no independent network or file permissions.

## Remaining engineering acceptance gates

1. Exercise a distribution-signed app on a clean Mac: real card grants, reinsertion,
   stale bookmarks, NAS reconnect, permission denial, sign-out, service interruption,
   retry and eject. Unit tests and local smoke checks do not replace this acceptance pass.
2. Validate representative ML inference and model downloads from the sandbox, HTTPS
   trust, memory pressure and forced stop during native inference. The Python runtime
   uses bundled certifi trust roots and a bundled OpenSSL configuration. Audit all
   native package binaries, licenses, required-reason APIs and model behavior before
   submission; imports alone are not full model testing.
3. Validate migration from the old standalone `social.hotmess.hedonism-uploader`
   identity to `host.lumiere.Cogsworth`, including credentials and preferences.
   The uploader service has its own ledger; server hash preflight remains authoritative
   for avoiding duplicate content when old local history is absent.
4. Complete App Privacy and third-party SDK manifests against the final ML environment.
   Required-reason declarations for native preferences/file timestamps are not a
   complete data-collection disclosure.

## Review and operational gates

- Resolve Facebook login guideline 4.8 with a qualifying alternative or a supported
  exception. Device codes alone do not establish an exception. Validate account
  deletion initiation if account creation is supported by the connected sign-in flow.
- Publish working HTTPS privacy and support pages and link them inside the app.
  Reconcile `docs/privacy-launch.md` with the deployed service. Include uploaded photos,
  embedded EXIF/location, account identifiers, face processing, retention and deletion.
  Archive registration also transmits the Mac name and selected folder paths; disclose
  their purpose and review data minimization. Do not select “Data Not Collected.”
- Confirm native authentication, deduplication and archive-registration endpoints and
  required migrations are deployed. Test expired credentials, revoked access, offline
  operation, failed uploads, retry, and sign-out while the worker is active.
- Supply a dedicated review account and reproducible sample-file workflow via App Store
  Connect review details. Do not commit secrets. A ten-minute device code is not a
  durable reviewer credential. Keep the test service available throughout review.
- Capture real macOS screenshots after the sandbox UX is complete, using synthetic or
  consented photos. Complete age rating, content rights, export compliance and App
  Privacy against the actual shipping app. Chip's answers are not automatically valid
  for a Mac build that may contain Python and additional cryptographic libraries.
- Archive with Mac App Store distribution signing, validate in Xcode Organizer, then
  upload to TestFlight. Verify the processed build and run signed-build acceptance
  tests before choosing a build for App Review. Increment build numbers on uploads.

## Entitlements and signing

`macOS/Cogsworth.entitlements` is wired into the `AppStore` configuration:

| Entitlement | Purpose |
| --- | --- |
| `com.apple.security.app-sandbox` | Required Mac App Store sandbox |
| `com.apple.security.network.client` | HTTPS API/storage and outgoing Action Cable connections |
| `com.apple.security.files.user-selected.read-only` | Read selected cards and inspect registered archive folders |
| `com.apple.security.files.bookmarks.app-scope` | Persist user-granted folder access across launches |

Current archive registration does not write originals, so read/write permission is
not requested. There is no incoming server, shared Keychain group, Apple Events
automation, camera capture or microphone use requiring those capabilities. No broad
filesystem exceptions or hardened-runtime exceptions are added. Test the worker's
native dependencies before deciding whether a narrowly justified runtime exception
is needed. The AppStore configuration enables hardened runtime.

`macOS/UploaderXPC/Uploader.entitlements` and `macOS/MLXPC/ML.entitlements`
are wired into their XPC targets. Each contains only App Sandbox and outgoing network
client access. XPC services have independent sandboxes; neither uses `inherit`.
The uploader receives a live folder grant via the bookmark passed by the app, rather
than an entitlement granting broad filesystem access. The ML service uses its own
container for caches and receives no direct card access. PyTorch's bundled
`torch_shm_manager` utility uses `PythonChild.entitlements` with exactly App Sandbox
and inheritance, as required for a child command-line tool by
[Apple's sandbox documentation](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html).
The XPC services themselves continue to use independent sandboxes.

Select the developer team and a Mac App Store provisioning profile in Xcode. Do not
hard-code profile-derived application/team identifiers in these entitlements. Inspect
the final signed app with `codesign -d --entitlements :- <app-path>` and verify nested
code with `codesign --verify --deep --strict <app-path>`. Test the signed sandbox build
on a clean user account; an unsigned build cannot validate effective entitlements.

## Draft listing

Name: **Cogsworth**

Subtitle: **Photo uploads for Lumière**

Keywords: `photography,camera,upload,RAW,SD card,Lumiere`

Description:

Cogsworth connects your Mac to your Lumière photographer account. Upload supported
photos from camera cards, follow progress from the menu bar, and skip content already
uploaded to your account. Failed files can be retried on a later upload.

Connect local or mounted network folders to register their availability with your
photographer account, and open Lumière's web administration tools to manage your archive.
Folder registration does not itself copy or archive originals.

A Lumière photographer account and internet connection are required. This release
targets Apple silicon Macs running macOS 14 or later.

Finalize copy after sandbox and worker decisions. Do not promise unattended access to
every card, NAS archive transfers, bundled AI processing, or uploads while the Mac sleeps.

## Local validation

```sh
swift test --package-path mac/HedonismUploader
xcodebuild -project apple/LumiereUploader.xcodeproj -scheme Cogsworth-AppStore \
  -configuration AppStore -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/Cogsworth-AppStore-Preparation CODE_SIGNING_ALLOWED=NO build
COGSWORTH_SIGNING_IDENTITY="<Apple Development or Developer ID identity>" \
  mac/HedonismUploader/script/test-xpc.sh /tmp/Cogsworth-AppStore-Preparation/Build/Products/AppStore/Cogsworth.app
bundle exec rubocop --cache false --no-parallel
```

Unsigned build success does not establish sandbox, signing or review readiness.

Implementation validation (2026-10-08):

- AppStore configuration builds with both XPC services embedded.
- 24 Swift tests pass, including lifecycle, duplicate-start and selected-folder scanning checks.
- 20 Python worker tests pass, including status framing/redaction at the native bridge.
- The disposable Developer ID-signed smoke app passes strict nested signature checks,
  launches both sandboxed services, rejects malformed upload requests, and transfers a
  folder grant. A loopback fixture verifies synthetic file bytes, upload completion and
  server-confirmed deduplication on a second request over the same XPC connection.
  The ML check imports isolated Python plus native dependencies, rejects a second
  interpreter initialization and acknowledges shutdown.
- The smoke script checks the effective signed entitlements against the minimal expected
  set, requires exactly two XPC services, and checks Python is confined to the ML service.
  The fixture HTTP server runs outside the app; neither helper gains server permission.
- The smoke app uses fresh bundle identifiers and empty containers. It does not use
  saved credentials or contact the production service. Ad-hoc signing cannot validate
  this hardened-runtime library setup because its binaries lack matching Team IDs.
- RuboCop is clean. Existing unused Keychain return-value and optional App Intents
  metadata warnings do not prevent the native build.

Real authenticated uploads and model inference/downloads remain acceptance gates
for release. Distribution provisioning and the build 4 archive succeeded for
`host.lumiere.Cogsworth`; the distribution-signed entitlement audit passed.
Upload `a83051f4-bbcb-4008-a42c-be31a3f588f8` targets app `6820789559`.
Xcode reported `EXPORT SUCCEEDED`; App Store Connect reports `PROCESSING`
(verified 2026-10-09). This confirms delivery, not TestFlight installation readiness.
Third-party Python binaries produced nonblocking missing-dSYM warnings.
No build has been submitted for App Review.

Historical delivery to the incorrect app record (not the intended Cogsworth app):

- App: `6820751783`; version `1.0.0`, build `3`.
- Upload: `dd559567-7f3a-424c-8b17-24d812aade0b`.
- Xcode reported `EXPORT SUCCEEDED`; App Store Connect now reports upload `COMPLETE`
  and build processing state `VALID` (verified 2026-10-09).
- Internal and external TestFlight state is `MISSING_EXPORT_COMPLIANCE`. Complete
  the encryption declaration before distributing to testers.
- Archive: `/tmp/Cogsworth-TestFlight-3.xcarchive`.
- Build 3 passes the signed XPC smoke test after removing the unused protocol compilers
  and sandboxing the PyTorch shared-memory utility.
- Apple warned that prebuilt third-party Python libraries lack dSYMs; these did not
  block upload, but limit native crash symbolication for those libraries.

## Python bundling reference and implementation direction

Reviewed the user-provided [garage-rag](https://github.com/lwm-luminx/garage-rag)
at commit `2076dbb1a85dedb8193911f4f98b5a17e86a89ab` on 2026-10-08.
Its source provides a concrete framework/XPC implementation; this inspection does
not establish that its current build has passed App Review.

- [`ext/python/BUILD.bazel`](https://github.com/lwm-luminx/garage-rag/blob/2076dbb1a85dedb8193911f4f98b5a17e86a89ab/ext/python/BUILD.bazel)
  builds and signs CPython as `Python.framework` and removes unneeded command-line
  tools before packaging. Cogsworth converts its locked standalone runtime into a
  versioned framework, with no interpreter executable in the host.
- [`macapp/README.md`](https://github.com/lwm-luminx/garage-rag/blob/2076dbb1a85dedb8193911f4f98b5a17e86a89ab/macapp/README.md)
  describes the shared runtime framework containing the standard library, extension
  modules and site-packages, linked by the native XPC services. It also documents
  bundled OpenSSL configuration, macOS certificate trust and native dependency loading.
- [`GaragePythonEmbed.c`](https://github.com/lwm-luminx/garage-rag/blob/2076dbb1a85dedb8193911f4f98b5a17e86a89ab/macapp/Sources/PythonXPCService/CPythonEmbed/GaragePythonEmbed.c)
  initializes CPython through isolated `PyConfig`, with explicit module paths,
  environment/user-site isolation and bytecode-writing controls. Its runtime smoke
  tests exercise the same startup mechanism as its XPC services.

Implemented direction: a native Cogsworth AI/ML XPC service embeds CPython. Use plain `NSXPCConnection` with a
typed Objective-C-compatible protocol for configuration, start/stop, readiness,
progress and errors. The user explicitly selected plain XPC: do not introduce gRPC,
protobuf, or a local HTTP/TCP bridge for app-to-worker communication. The native
service invokes embedded Python directly through the embedding shim. Handle XPC
interruption/invalidation and worker shutdown explicitly. This local IPC decision
does not replace the worker's existing remote service connections.

The implementation uses two bundled services: a native uploader and a single AI/ML
worker hosting Python. Each service admits one client connection; repeated start
requests cannot create parallel ML sessions. Interruption/invalidation ends the
service session; Python is never finalized and reinitialized inside a live process.

Keep the existing Python version
until all locked ML dependencies have been validated; Garage's free-threaded 3.14
runtime is not a drop-in replacement for Cogsworth's 3.13 dependency environment.
The framework build, native embedding shim, XPC lifecycle integration, nested signing
and offline smoke harness are now present; distribution acceptance remains pending.
Test imports, HTTPS certificate validation, writable container caches, credential
updates and shutdown from a relocated signed app without Homebrew or a source checkout.

The initial spawned-child inheritance entitlements have been superseded by the two
XPC targets' own sandbox entitlements. Garage's incoming-network, read/write-file
and App Group permissions are not copied into Cogsworth.

The reference does not remove the card-folder permission or privacy gates above.

## Apple documentation

- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Sandbox file access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (2.4.5, 2.5.2, 4.8 and 5.1)
- [Distribution preparation](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)
