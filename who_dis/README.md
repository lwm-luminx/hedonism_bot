# who_dis

Authenticated Action Cable inference worker for Lumière. Rails keeps work in PostgreSQL; workers claim photographer-scoped jobs over a private WebSocket connection. Every action rechecks the service-account credential. Heartbeats renew bounded leases, and results are applied only while the lease is valid. Completion acknowledgments can be retried safely.

```sh
cd who_dis
uv sync --frozen
uv run python -m hedonism.who_dis
uv run pytest
```

Set `CABLE_URL=wss://api.lumiere.host/cable`, `GRAPHQL_URL=https://api.lumiere.host/graphql`, and `API_KEY` to a service-account bearer token. Plain WebSocket connections are permitted only on localhost for development. Tokens are sent in the Authorization header, never the URL.

Cogsworth embeds Python 3.13 and the frozen dependencies. Models load lazily and download weights on first use; their writable caches live outside the signed app in Application Support/Cogsworth/Models.

## Docker

```sh
docker build -t hedonism_who_dis who_dis
docker run --env-file worker.env -v who_dis_models:/models hedonism_who_dis
```

Keep the service token in a private environment file. Mount `/models` to retain downloaded weights. Celery and a Redis broker are no longer required.
