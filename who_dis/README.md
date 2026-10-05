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
