# Hedonism Bot

A Rails application with a React/Relay frontend built by Vite, a Python ML worker,
and a macOS photo uploader.

## Development

When checked out as AudienceKit's `apps/hedonism_bot` submodule, follow its
[local stack guide](../../docs/development/LOCAL_STACK.md). From the monorepo root,
`mise run hedonism:setup` prepares dependencies and databases, and
`mise run hedonism:dev` starts Rails on **3100**, Vite on **3036**, the Relay watcher
and the Solid Queue worker. `Procfile.dev` uses Solid Queue's `async` mode so the
development worker does not fork after native libraries have loaded on macOS. The IntelliJ **AudienceKit - Full development stack**
target also starts the AudienceKit API and admin Vite server. The Python ML worker
is configured separately below.

AudienceKit's **Local HTTPS stack** compound (or `mise run dev:https` at the
monorepo root) serves this app at `https://hedonism.local.audiencekit.com` through
nginx. Its HTTPS task uses relative Vite asset URLs and wss on port 443; nginx
routes `/vite-dev/` directly to port 3036. Follow the guide's mkcert setup first.

Use the Ruby and Bun versions in `.ruby-version` and `.bun-version`. The app needs
PostgreSQL with PostGIS and pgvector, Redis, libvips, exiftool, and OpenBLAS.

```sh
bun install --frozen-lockfile
bin/setup --skip-server
bin/dev
```

Vite serves the frontend; Relay regenerates GraphQL artifacts in watch mode.

## Checks

```sh
bin/rubocop
bundle exec rspec
bun run test:run
bun run build
bun run knip
bin/steep check
```

RSpec isolates local uploads by process and removes them after each suite.
Keep the RAW/HEIF fixtures: image processing tests use all six pairs.
Knip excludes CSS imports and tools used outside frontend source from dependency checks.

## Python worker

The Celery worker that handles the ML tasks enqueued by this app lives in
[`who_dis/`](who_dis/README.md) (merged from `hedonism_who_dis` with its history).

## Deploying to Heroku

The web app runs on Heroku's container stack from `heroku.yml` (the Dockerfile builds clusterkit's
Rust extension, installs exiftool and libvips, and builds the Vite frontend).

```sh
heroku create <app> --stack container
heroku addons:create heroku-postgresql:essential-1 -a <app>   # postgis + pgvector are enabled by the schema
heroku config:set HOT_BUCKET_NAME=… HOT_ACCESS_KEY_ID=… HOT_SECRET_ACCESS_KEY=… HOT_ENDPOINT=… -a <app>  # photo storage (R2), see Storage tiers
heroku config:set RAILS_MASTER_KEY=… RAILS_MAX_THREADS=5 SOLID_QUEUE_IN_PUMA=1 -a <app>
git push heroku main
```

The release phase runs `bin/rails heroku:release`: `db:prepare` for the primary database, then the
Solid Cache/Queue/Cable schemas, which share the one Heroku database. Set `REDIS_URL` once the
`who_dis` worker is deployed; until then photo captioning and face jobs fail to enqueue.

## Storage tiers

Photos are stored in a hot bucket billed per GB, Cloudflare R2 in production, set with these
config vars (without them the app falls back to Bucketeer when `BUCKETEER_BUCKET_NAME` is set):

```sh
heroku config:set HOT_BUCKET_NAME=… HOT_ACCESS_KEY_ID=… HOT_SECRET_ACCESS_KEY=… \
  HOT_ENDPOINT=https://<account id>.r2.cloudflarestorage.com -a <app>   # HOT_REGION defaults to auto
```

Browsers upload originals straight to the bucket, so give it a CORS rule allowing `PUT` from the
gallery hosts with the `Content-Type`, `Content-MD5` and `Content-Disposition` headers. Each file
remembers the service it was stored on, so photos already on Bucketeer keep loading after the switch;
copy them over (and delete them from Bucketeer) with:

```sh
heroku run bin/rails storage:move_to_hot FROM=bucketeer -a <app>   # safe to rerun
```

Once it reports nothing left to move, the Bucketeer add-on can be removed.

Admin → Storage shows how much each album stores and lets a photographer move an album's
originals (RAW and camera HEIF) to cheaper archive storage and back; JPEG previews always stay in
the hot service so galleries keep loading. The archive is a separate bucket, enabled by setting
these config vars:

```sh
heroku config:set ARCHIVE_BUCKET_NAME=… ARCHIVE_ACCESS_KEY_ID=… ARCHIVE_SECRET_ACCESS_KEY=… -a <app>
# Optional: ARCHIVE_REGION (default us-east-1), ARCHIVE_STORAGE_CLASS (default GLACIER_IR on AWS;
# set it to "" for Backblaze B2 or Cloudflare R2), ARCHIVE_ENDPOINT (B2/R2 S3 endpoint).
```

GLACIER_IR still reads instantly, but AWS bills it for at least 90 days, so restoring an album
sooner still costs the remaining days.

## Photographers (tenants)

Gallery requests are served for one photographer, picked by their host: a hostname registered in
`photographer_domains` first, then a single subdomain under `lumiere.host`. Hosts that
match no photographer get a 404. GraphQL IDs only resolve to records the request's photographer owns.

```sh
bin/rails photographers:create SUBDOMAIN=luminx NAME="Luminx"
bin/rails photographers:add_domain SUBDOMAIN=luminx HOST=gallery.luminx.media
bin/rails photographers:list
```

### Service domains

`SERVICE_DOMAIN` defaults to `lumiere.host`:

- `lumiere.host` hosts the static marketing site on GitHub Pages; `www.lumiere.host` redirects to it.
- `api.lumiere.host/graphql` serves the shared GraphQL API on Heroku; pass a photographer’s service-account bearer token.
- `<photographer>.lumiere.host` serves that photographer’s gallery on Heroku, including its same-origin GraphQL endpoint.
- `api` and `www` are reserved and cannot be photographer subdomains.
- Registered custom domains continue to serve their assigned photographers.

The static marketing source lives in `marketing/`. The published copy is on the `gh-pages`
branch of `lwm-luminx/hedonism_bot`; GitHub Pages publishes that branch’s root.
To update the marketing site, publish the files in `marketing/` to that branch.
The `CNAME` file sets `lumiere.host` as the canonical domain.

Heroku domain routing for `api.lumiere.host` and `*.lumiere.host` is registered on
`hedonism-bot`, with ACM enabled and `SERVICE_DOMAIN=lumiere.host`.
Namecheap BasicDNS uses these records (configured October 8, 2026):

| Type | Host | Target |
| --- | --- | --- |
| ALIAS | `@` | `lwm-luminx.github.io` |
| CNAME | `www` | `lwm-luminx.github.io` |
| CNAME | `api` | `integrative-cod-dr5iwtm5lgnuqswrupj8330t.herokudns.com` |
| CNAME | `*` | `crystalline-wildwood-b778qrj3zc1qt0dhbudux90g.herokudns.com` |

Create the `luminx` photographer using the command above to serve `luminx.lumiere.host`.
Heroku ACM issued certificates for the API and wildcard domains on October 8, 2026;
both API health and the Luminx gallery returned HTTP 200 over HTTPS. GitHub Pages
built the marketing site, and it returned HTTP 200 when queried directly at a Pages
address. DNS propagation and the marketing certificate are still pending. Enable
HTTPS enforcement in the repository’s Pages settings once its certificate is issued. The Rails domain-routing changes need a separate app deployment.


### AudienceKit Photography provider

`POST /extensions/photography/graphql` exposes a separate read-only schema,
exported at `app/graphql/photography/schema.graphql`. The existing `/graphql`
endpoint continues to expose its legacy PhotoTake-as-Photo contract.

Create an explicit audience grant (UUIDs belong to the provider photographer and
AudienceKit audience respectively):

```sh
bundle exec rake 'photography:grant[PHOTOGRAPHER_UUID,AUDIENCE_UUID]'
bundle exec rake 'photography:publish[GRANT_UUID,PHOTO_UUID]'
bundle exec rake 'photography:unpublish[GRANT_UUID,PHOTO_UUID]'
bundle exec rake 'photography:revoke[GRANT_UUID]'
```

The grant command prints a credential once; only its SHA-256 digest is stored.
Give it to the AudienceKit platform admin configuring the connection. Each grant
belongs to exactly one photographer and audience. An empty grant shares no photos;
publication accepts only logical Photos owned by that photographer. Reads further
exclude unprocessed/hidden takes and photos moved to another photographer. Revoked
grants and inactive photographers cannot read data. These credentials are distinct
from the service accounts used by uploaders.

The endpoint accepts either a single operation object or a JSON array of 1–20
operations. Each operation includes `query`, `variables` and
`extensions: {"accessToken": "..."}`. Credentials are independently authenticated
and parameter-filtered per operation. Responses retain request order and errors
are isolated per query. There is no mutation root and no access to faces or user
identities through this schema.

```graphql
query ProviderPhotos($audience: ID!, $first: Int!, $after: String) {
  contractVersion
  photographer(audienceId: $audience) {
    id
    name
    photos(first: $first, after: $after) {
      nodes { id previewUrl takeCount }
      pageInfo { endCursor hasNextPage }
    }
  }
}
```

Photo IDs represent logical Photo groups. Previews and counts use processed takes;
the complete PhotoTake/PhotoPerson contract and venue/event mapping follow in later
slices. The maximum photo page is 50. Deploy this endpoint and issue grants before
activating AudienceKit connections; no existing photo library is automatically shared.
