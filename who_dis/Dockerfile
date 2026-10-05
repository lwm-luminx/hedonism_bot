# syntax=docker/dockerfile:1
# check=error=true

# Celery worker that runs the ML tasks enqueued by the Rails app.
# docker build -t hedonism_who_dis who_dis
# docker run -d -e REDIS_URL=redis://redis:6379/0 -e GRAPHQL_URL=http://web/graphql -e API_KEY=<key> hedonism_who_dis

ARG PYTHON_VERSION=3.13
FROM docker.io/library/python:$PYTHON_VERSION-slim-bookworm AS base

# opencv (pulled in by deepface) needs libGL and glib at runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Throw-away build stage to reduce size of final image
FROM base AS build

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Install dependencies first so they're cached separately from the code
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project --python python3

COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --python python3


# Final stage for worker image
FROM base

# Model weights are downloaded on first use; mount a volume at /models to keep them between runs
ENV PATH="/app/.venv/bin:$PATH" \
    HF_HOME=/models/huggingface \
    DEEPFACE_HOME=/models \
    REDIS_URL=redis://redis:6379/0

RUN groupadd --system --gid 1000 worker && \
    useradd worker --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir /models && chown worker:worker /models
USER 1000:1000

COPY --chown=worker:worker --from=build /app /app

VOLUME /models

CMD ["celery", "-A", "hedonism.who_dis.app", "worker", "--loglevel", "INFO", "--pool", "threads"]
