# Facebook data deletion callback design

Status: implemented locally, October 8, 2026. The original design below is followed by the implementation/deployment runbook and its remaining operational prerequisites. Production deployment and Meta dashboard verification have not been performed.

## Contract and verification

Implement a public HTTPS POST endpoint accepting the form field `signed_request`, authenticate it using the Facebook app secret, durably accept the deletion, and return HTTP 200 with:

```json
{
  "url": "https://<canonical-app-host>/privacy/deletion/0123456789abcdef0123456789abcdef",
  "confirmation_code": "0123456789abcdef0123456789abcdef"
}
```

The URL must let the requester inspect progress without signing in. Generate the alphanumeric code with `SecureRandom.hex(16)`; do not derive it from an email, Facebook ID, or sequential database ID.

Primary reference: [Meta Data Deletion Request Callback](https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback/), also historically published at [Deleting App Data](https://developers.facebook.com/docs/apps/delete-data/). These pages could not be retrieved during this review (HTTP 429 / inaccessible). The contract above follows the established callback protocol; checking the current primary documentation and exercising the dashboard's available deletion test are release gates, not completed verification. Retention periods and operational targets below are proposed application policy, not claims about Meta-mandated deadlines.

## Scope for this app

Facebook is currently the only user sign-in method: `SessionsController#create` creates a `User` from Facebook profile data and stores its UUID in the Rails session. Therefore, treat deletion for the configured login app as removal of the corresponding personal account and its associated personal data across photographer tenants. A tenant hostname must not narrow that scope. Preserve photographer organizations and their independently owned assets.

Resolve the signed app-scoped `user_id` against `users.facebook_id` as an exact decimal string. Never identify a user by email or accept a local UUID supplied by the caller. Update the login writer to stop coercing Facebook IDs through `to_i`.

The schema also contains `audience_applications` and `audience_users.facebook_id`, but does not explicitly associate each identity with a Facebook app. Do not search those IDs globally or try every tenant secret. This endpoint serves only `FACEBOOK_APP_ID`, authenticated with `FACEBOOK_APP_SECRET` from `config/initializers/facebook.rb`. Before enabling callbacks for additional apps, introduce explicit identities with a unique `(facebook_app_id, app_scoped_user_id)` key and verified mapping to the local user. Audit legacy identity provenance before rollout; ambiguous mappings need resolution rather than deleting a potentially unrelated account.

## Routes and authentication

| Route | Behavior |
| --- | --- |
| `POST /callbacks/facebook/data-deletion` | Verify signed request; persist receipt and deletion intent; return required JSON. |
| `GET /privacy/deletion/:confirmation_code` | Minimal HTML status page; optional JSON representation. |

Use a dedicated controller inheriting from `ActionController::Base`, avoiding `ApplicationController#set_photographer`, session authentication, and tenant redirects. Exempt only the POST action from Rails CSRF checking: the verified signature authenticates this server-to-server request. Keep normal CSRF protection elsewhere. Configure Rails host authorization and the proxy for the canonical host.

Configure a trusted `DATA_DELETION_PUBLIC_ORIGIN` (HTTPS, host only) and construct status URLs from it. Never use the request Host or forwarded headers as the origin.

The verifier must:

1. Require a scalar string, apply a small request-size limit, and require exactly two nonempty dot-separated base64url segments.
2. Strictly decode the signature and payload, allowing valid base64url padding; reject invalid alphabet, padding, JSON, and non-object payloads.
3. Compute HMAC-SHA256 over the **original encoded payload segment**, using `FACEBOOK_APP_SECRET`. Require a 32-byte decoded signature and compare in constant time.
4. Require the authenticated payload's algorithm to be `HMAC-SHA256` (case-normalized) and its `user_id` to be a nonempty decimal string. If an app ID is present, require it to match the configured app; the secret determines the app context regardless.
5. Validate the shape of `issued_at` if supplied. Do not invent a short expiration window that would reject legitimate delayed delivery; confirm any freshness requirement against Meta's current protocol. Use durable idempotency for replay handling.

Return a uniform `400 {"error":"invalid_signed_request"}` for malformed or invalid signatures, with no deletion side effects. Missing server credentials or unavailable durable storage return 503, never a successful receipt. Apply rate limits without assuming a fixed Meta IP allowlist.

## Durable requests and replay handling

Add `DataDeletionRequest` with a UUID primary key, unique random confirmation code, app ID, keyed subject digest, payload digest, encrypted app-scoped user ID, nullable local-user reference, status, timestamps, attempt count, sanitized error category, and an internal cleanup manifest. Never retain the raw signed request or access token in this table. Use a dedicated key for subject HMACs, separate from the Facebook secret. Digests remain sensitive pseudonymous data.

Use states `pending → processing → completed`, with `retrying` for recoverable errors and `needs_attention` for exhausted retries. The public view maps both error states to “Deletion delayed; we are working on it,” without internal details. Unknown subjects receive an ordinary receipt and completed status after confirming no matching data; do not expose whether an account existed.

Within one primary-database transaction, serialize acceptance for `(app_id, subject_digest)`, create the receipt, mark the user `deletion_pending_at`, revoke local access, and persist a work item. Repeated identical signed payloads return the same receipt through a unique `(app_id, payload_digest)` constraint. Concurrent requests for the same subject reuse active work. A new request following a genuinely new sign-in must be able to delete the new account; never treat a historical completion as a permanent exemption.

Persist work in the primary database rather than relying on successful enqueue to Solid Queue's separate database. After commit, enqueue `FacebookDataDeletionJob` with only the receipt UUID. A recurring dispatcher re-enqueues pending/stale work, closing the commit/enqueue crash window. Workers take a lock or renewable lease and all cleanup operations tolerate already-missing records.

Keep encrypted identity/replay material for a proposed 90-day receipt window, then erase it and retain only the minimal non-identifying receipt if needed. Document what happens after expiry. Exact replay protection ends when its stored key expires; a replay after that point must still be harmless and must never restore data.

## Deletion plan grounded in the schema

Do not start with `User.destroy!`. Its current `has_one :photo_take` assumes a nonexistent `photo_takes.user_id`; several inbound foreign keys have no cleanup association, and the through-audience destroy option needs removal/review. Use an explicit service with a reviewed dependency manifest, then delete the user last.

| Data | Required handling |
| --- | --- |
| `users` | Erase names, email, demographics, social IDs, raw Facebook graph, tokens, scopes, and ultimately the row. |
| `sessions`, `user_locations` | Delete locations before their sessions. Reject existing cookies as soon as deletion is pending; audit any legacy JWT consumers to ensure tokens cannot authorize solely from embedded claims. |
| `audience_users`, `audience_admins`, `photographer_admins`, `tribe_users` | Delete memberships and grants, preserving audiences, photographers, and tribes. Some tables lack corresponding models; use explicit table access where needed. |
| `user_likes`, `user_rsvps`, `reviews`, `pings`, `venue_messages`, `user_pages` | Delete subject rows, including page access tokens. |
| `friendships`, `friendship_links` | Delete links referencing either `user_id` or `friend_id`, and links belonging to friendships involving either `friend_low_id` or `friend_high_id`; delete those friendships afterward. |
| `tickets` | Default to deleting the user's ticket rows. Any required transaction retention must be explicitly established and separated from Facebook identity; do not silently retain identifiable records or claim full deletion. |
| `faces`, `photo_faces` | Capture subject-linked face IDs before deleting anything. Erase their aggregate and per-photo embeddings, face crops, and identifying links. `Face` currently nullifies `photo_faces`, which alone leaves biometric data behind. |
| `photo_takes.facial_metadata` | Remove corresponding derived face data, with a persistent processing exclusion so inference cannot recreate it. Where region-level cleanup cannot be proved, suppress recognition for the affected take and clear its facial metadata and derived face records. Preserve independently owned original photos unless separately in deletion scope. |
| `users.image_id`, `images`, Active Storage | Remove the user's profile-image reference; purge exclusively owned profile content, variants, remote objects and cached copies. Shared/deduplicated images require reference and provenance checks before deleting the blob. |
| `pages.facebook_access_token`, `pages.facebook_graph`, `events.facebook_graph` | Audit data obtained under the subject's grant. Add token/source provenance so subject-derived credentials and personal fields can be erased without deleting unrelated shared pages/events. Unknown provenance blocks a completion claim until resolved. |
| External copies | Audit logs, error reporting, caches, storage replicas/archive tiers, and the Twilio new-user notification containing a first/last name in `User.from_facebook_graph`. Remove personal notification content going forward and establish cleanup/retention handling for existing copies. |

Also inventory `social_links.object_id`, safety-report identifiers, and unstructured graph/metadata fields: the absence of a user foreign key is not evidence that they contain no subject data. Unrelated safety or organization data is not automatically deletable just because it shares an identifier; establish provenance and any retention basis.

Tenant service accounts belong to photographers, not users in the current schema. Do not delete all photographer credentials or albums merely because an administrator requested deletion. If personal service-account ownership is introduced, include it in the manifest.

## Prevent resurrection and report completion accurately

Every authentication path must reject pending users. Login and deletion acceptance must share subject-level serialization, including the no-user case, so a simultaneous login cannot recreate data while work is running. Workers/importers must check deletion state inside the same locking/transaction boundary as their writes. After completion, a deliberate new Facebook authorization may create a fresh account, but stale jobs must never repopulate the old UUID.

Face inference, preview extraction, and clustering require persistent exclusions for affected takes, enforced at write time as well as query selection. Clearing `facial_metadata` alone is unsafe: `InferJob` selects takes where that field is nil. Preserve a non-identifying processing exclusion even after deleting the user.

Use a durable cleanup manifest for external object keys and processor work before deleting relational pointers. Purge external content idempotently, track acknowledgments, and clear manifest identifiers once cleanup is confirmed. Do not mark completion merely because `purge_later` was enqueued. Handle partial failure without rolling back the access block.

Completion means the reviewed live-data manifest is cleared and required external cleanup is confirmed. Backups need a documented expiry and a restricted deletion journal applied before a restore serves traffic; journal retention must cover the longest backup lifetime, independently of receipt retention. Do not promise immediate backup erasure. The status page must state any remaining backup expiry or authorized retention accurately.

## Status page and operations

Show only confirmation code, requested/completed timestamps, progress, and an operational support contact. No name, Facebook ID, email, tenant, record counts, or account-existence indicator. Treat the URL as a bearer capability: HTTPS, `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, no analytics or third-party resources, no indexing, and generic 404s for unknown codes.

Filter `signed_request`, confirmation codes, and identity fields from Rails parameters and telemetry; also redact status URL path segments in proxy/access logs. Store only sanitized error categories in receipts. Alert on aged pending requests, exhausted retries, or cleanup failures using receipt UUIDs.

Proposed operational target: begin processing within minutes and alert at 24 hours incomplete. Establish the actual deletion deadline and backup retention in the privacy policy before release; do not label these targets Meta requirements.

## Implementation and acceptance checks

Proposed components: `Facebook::SignedRequestVerifier`, `FacebookDataDeletionsController`, `DataDeletionRequest`, `FacebookDataDeletionJob`, `UserDataDeletionService`, a cleanup work-item table, a recurring dispatcher, and a minimal server-rendered status view. Migrations also add the pending-user flag, processing exclusions, and provenance needed for reliable cleanup. Keep this separate from any future deauthorization callback.

Acceptance tests must cover:

- Valid signed form POST returns exact `url`/`confirmation_code` shape and a reachable unauthenticated page on the canonical host, without photographer resolution or CSRF failures.
- Tampered signatures, wrong secret/algorithm, malformed base64/JSON, missing or non-scalar input, and oversized input cause no writes.
- Duplicate and concurrent callbacks, unknown/already-deleted users, enqueue failure, worker crashes, expired leases, and partial external purge failures behave idempotently and never report premature success.
- A fixture spanning every inbound user foreign key deletes cleanly; a second user's data and shared photographer/audience records survive.
- Face crops, both embedding layers, profile blobs, raw metadata, page credentials, external copies, and CDN caches follow the manifest; inference cannot regenerate deleted derivatives.
- Cookies and legacy tokens cannot authorize after acceptance; simultaneous login and stale background writes cannot recreate deleted data; deliberate later authorization gets a fresh account.
- Public status and all logging surfaces disclose no identity, signature, secret, or capability token. Restore rehearsal applies deletions before traffic is enabled.

Rollout: resolve the provenance/retention items above, implement and run the checks, deploy HTTPS routes and workers, set the Meta app's Data Deletion Callback URL to the POST route, and perform a real test-account deletion using the current dashboard workflow. A design or a successful JSON response alone does not establish compliance.

## Implemented integration and operator runbook

The repository now includes the POST callback, HTML/JSON status endpoint, signature verifier, receipt/outbox, row-locked retryable worker, dispatcher, personal-row cleanup, profile/face blob purging, pending-user login guards, and biometric write exclusions. Receipts contain keyed identity digests, a temporary local UUID, and authenticated encrypted review context with the identifiers required to locate legacy copies. The context is erased at review completion and never rendered publicly. Identical deliveries and deliveries coalesced into active work retain replay digests. No user-to-audience cascade runs during erasure.

### Deployment

1. Run `bin/rails db:migrate` in the deployment environment.
2. Set `DATA_DELETION_PUBLIC_ORIGIN=https://<canonical-host>` alongside the existing Facebook app ID/secret. Keep the Rails secret-key base stable: its key generator derives separate identity-digest and review-context encryption keys. Key rotation requires migrating the digest/replay strategy first.
3. Ensure the canonical host reaches Rails without photographer routing at the proxy, passes host authorization, and uses HTTPS. Configure proxy/CDN/access-log redaction for `/privacy/deletion/*` and callback form bodies. Rails redacts its own status paths and signed parameters; upstream logs are outside its control. Add edge rate limits appropriate for callbacks.
4. Run Solid Queue with its recurring scheduler. `DispatchDataDeletionsJob` scans the primary-database outbox every minute. Deploy a scheduled equivalent if the hosting worker does not run recurring tasks. Route the overdue/failure log events into operator alerting.
5. Register `https://<canonical-host>/callbacks/facebook/data-deletion` as the Meta Data Deletion Callback URL, verify the current primary requirements, and exercise a test account. The status URL is returned automatically.

### Review and completion

Known-user requests automatically delete supported local personal data and attached profile/face objects, but remain `needs_attention` until an operator checks legacy external copies and provenance. Unknown subjects complete without revealing account existence. Shared profile images/blobs add explicit review reasons; shared gallery photos and organizations remain intact. Other unlinked photographs cannot be identified from a Facebook callback alone.

Use `bin/rails data_deletions:pending` to list internal receipt UUIDs and review categories. Before confirming a known-user receipt:

- Resolve the legacy identity/app mapping and shared profile-image cases. Check legacy audience identities, social-link objects, safety identifiers and raw graph data for additional subject data.
- Remove/re-authorize subject-derived page tokens and remove subject-derived personal fields from shared graph records. Do not delete other administrators' independent grants. The schema has no provenance for these copies, so automatic attribution would be unsafe.
- Remove applicable historical Twilio notifications, telemetry, external/CDN caches and storage replicas. New-user SMS messages now omit names. Confirm any remaining storage retention is authorized and accurately disclosed.
- Record/apply deletion in the restricted backup restore journal and confirm the published backup lifecycle. Use the encrypted `receipt.review_context` through a restricted Rails console to locate the old Facebook/user IDs, image sources, linked pages, and affected face/take IDs. Record the required restore-journal entry before confirming review, which erases that context. The receipt is not itself a complete backup restore journal.
- Replace the existing privacy-notice placeholders with an operational contact and actual retention practices. Keep the receipt UUID in the restricted operations record; do not put identifiers in public status or job logs.

Then run `RECEIPT_ID=<uuid> CONFIRM_REVIEW=complete bin/rails data_deletions:confirm_review`. The task refuses completion before local/blob cleanup. For a corrected technical failure, use `RECEIPT_ID=<uuid> bin/rails data_deletions:retry`; failures back off up to an hour and require attention after ten attempts. A review timestamp is recorded; no raw free-text PII is copied into the receipt.

Receipt expiry is deliberately not scheduled until backup/journal retention is established. Operators must configure a bounded retention/erasure policy before production; subject and delivery digests are pseudonymous data, not anonymous metrics. Completion also requires external/provenance review: this implementation does not silently assert that legacy copies, backups or processors have been erased. These operational steps cannot be validated from the repository alone.

The worker holds a receipt row lock during cleanup instead of using a renewable lease. Process crashes roll back local pointer changes, while external deletes are safe to repeat from the preserved pointers/manifest. The primary-database receipt remains pending/retrying for redispatch. Biometric operations share a transaction-scoped advisory lock so delayed inference responses and previews cannot recreate erased derivatives.
