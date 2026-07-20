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

Commit and push everything you want released first. `bin/build` refuses to run if there are
uncommitted changes to tracked files, and builds from `git archive` of the current commit rather
than the working directory, so the image can never drift from what the `v<version>` git tag points
to (untracked/ignored files are also excluded automatically, since `git archive` only ever includes
what's actually committed).

Run the build script with the version number to build and push a new release:

```bash
bin/build 1.0.0
```

This builds for `linux/amd64,linux/arm64` from the current commit and:
- Pushes `serpapi/serptrail:1.0.0` and `serpapi/serptrail:latest` to DockerHub
- Tags the built commit as `v1.0.0` and pushes the tag to `origin`

It refuses to run if `v<version>` already exists as a tag, to avoid silently rebuilding and
retagging a past release.
