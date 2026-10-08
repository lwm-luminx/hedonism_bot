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
heroku addons:create bucketeer:hobbyist -a <app>               # Active Storage uses Bucketeer when BUCKETEER_BUCKET_NAME is set
heroku config:set RAILS_MASTER_KEY=… RAILS_MAX_THREADS=5 SOLID_QUEUE_IN_PUMA=1 -a <app>
git push heroku main
```

The release phase runs `bin/rails heroku:release`: `db:prepare` for the primary database, then the
Solid Cache/Queue/Cable schemas, which share the one Heroku database. Set `REDIS_URL` once the
`who_dis` worker is deployed; until then photo captioning and face jobs fail to enqueue.

## Storage tiers

Admin → Storage shows how much each album stores and lets a photographer move an album's
originals (RAW and camera HEIF) to cheaper archive storage and back; JPEG previews always stay in
the main service so galleries keep loading. Bucketeer is billed by flat plan tier, so the archive is
a separate bucket billed per GB, enabled by setting these config vars:

```sh
heroku config:set ARCHIVE_BUCKET_NAME=… ARCHIVE_ACCESS_KEY_ID=… ARCHIVE_SECRET_ACCESS_KEY=… -a <app>
# Optional: ARCHIVE_REGION (default us-east-1), ARCHIVE_STORAGE_CLASS (default GLACIER_IR on AWS;
# set it to "" for Backblaze B2 or Cloudflare R2), ARCHIVE_ENDPOINT (B2/R2 S3 endpoint).
```

GLACIER_IR still reads instantly, but AWS bills it for at least 90 days, so restoring an album
sooner still costs the remaining days.

## Photographers (tenants)

Every request is served for one photographer, picked by its host: a hostname registered in
`photographer_domains` first, then the host's first label as the photographer's subdomain. Hosts that
match no photographer get a 404. GraphQL IDs only resolve to records the request's photographer owns.

```sh
bin/rails photographers:create SUBDOMAIN=luminx NAME="Luminx"
bin/rails photographers:add_domain SUBDOMAIN=luminx HOST=gallery.luminx.media
bin/rails photographers:list
```
