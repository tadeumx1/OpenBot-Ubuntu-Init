# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-24

### Added

- Initial lightweight Ubuntu setup kit for a local CopilotKit/OpenBot checkout.
- Safe installer that applies only kit-owned configuration files and creates a
  timestamped backup before replacing an existing configuration.
- `Makefile` commands for starting, stopping, restarting, checking status, viewing
  logs, and opening OpenBot locally.
- Ubuntu application-menu launcher with API, frontend, and PostgreSQL readiness checks.
- Local model profiles for ChatGPT Plan, Claude Plan, OpenCode Go, and an OpenAI API-key fallback.
- Git and Docker ignore rules that prevent local credentials, OAuth session data, and
  CopilotKit state from being committed or included in Docker build contexts.
- GitHub Actions validation for pushes and pull requests, plus automated GitHub
  Releases with a source archive and SHA-256 checksum for `v*` tags.

[Unreleased]: https://github.com/tadeumx1/OpenBot-Ubuntu-Init/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tadeumx1/OpenBot-Ubuntu-Init/releases/tag/v0.1.0
