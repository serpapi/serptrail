# Release

Images are published to DockerHub at `serpapi/serptrail` using the `bin/build` script.

## One-time setup

Create a `linux/amd64` builder (required when building on Apple Silicon):

```bash
docker buildx create --name serptrail-builder --use
```

Log in to DockerHub as the `serpapi` account:

```bash
docker login --username serpapi
```

## New versions

Run the build script with the version number to build and push a new release:

```bash
bin/build 1.0.0
```

This builds for `linux/amd64` and pushes two tags to DockerHub:
- `serpapi/serptrail:1.0.0`
- `serpapi/serptrail:latest`
