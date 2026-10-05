# hedonism_who_dis

Python Celery worker for hedonism_bot. The Rails app enqueues tasks onto the
`celery` queue in Redis (see `lib/celery.rb`), and this worker runs the ML
tasks (image captioning, facial data and visual feature extraction), writing
results back through the app's GraphQL API.

```sh
cd who_dis
uv sync
uv run celery -A hedonism.who_dis.app worker --loglevel INFO --pool=threads
uv run pytest
```

## Configuration

| Variable      | Default                         | Purpose                                   |
|---------------|---------------------------------|-------------------------------------------|
| `REDIS_URL`   | `redis://127.0.0.1:6379/0`      | Celery broker and result backend          |
| `GRAPHQL_URL` | `http://localhost:5000/graphql` | Rails GraphQL endpoint results are sent to |
| `API_KEY`     | (empty)                         | Bearer token sent to the GraphQL endpoint |

The Rails side reads the same `REDIS_URL` in `lib/celery.rb`.

## Docker

```sh
docker build -t hedonism_who_dis who_dis
docker run -v who_dis_models:/models -e REDIS_URL=... -e GRAPHQL_URL=... hedonism_who_dis
```

Model weights download on first use into `/models`; mount a volume there to keep them.
CI (`.github/workflows/docker.yml`) builds this image and the Rails image on every
PR and pushes both to `ghcr.io/lwm-luminx/` from `main`.
