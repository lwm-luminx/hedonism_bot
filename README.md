# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

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
