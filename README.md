# squid-docker-image

Public image repository for building and publishing the custom Squid container.

## What this repo contains

- `Dockerfile`: builds Squid from source and produces the runtime image.
- `.github/workflows/build-and-publish.yml`: GitHub Actions workflow to build and publish images to GHCR.

## Publish target

The workflow publishes to:

- `ghcr.io/abrar71/squid-docker-image:<tag>`
- `ghcr.io/abrar71/squid-docker-image:sha-<commit>`
- `ghcr.io/abrar71/squid-docker-image:latest` (for the default branch)

No runtime configs, certs, or local compose files are kept here.
