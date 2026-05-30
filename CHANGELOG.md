# Changelog

All notable changes to AppGrid are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries are generated from Conventional-Commit messages via
[`git-cliff`](https://git-cliff.org/). The config lives at `cliff.toml` —
to rebuild this file from the full history:

```sh
git cliff -o CHANGELOG.md
```

After tagging a release, append the new section without rewriting prior ones:

```sh
git cliff --tag vX.Y.Z --unreleased --prepend CHANGELOG.md
```

## [Unreleased]

<!-- git-cliff appends rendered entries here -->
