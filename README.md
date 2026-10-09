# Hedonism Bot

A Rails application with a React/Relay frontend built by Vite, a Python ML worker,
and a macOS photo uploader.

## Development

Use the Ruby and Bun versions in `.ruby-version` and `.bun-version`. The app needs
PostgreSQL with PostGIS and pgvector, Redis, libvips, exiftool, and OpenBLAS.

```sh
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
