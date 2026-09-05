# Changelog

All notable changes to this module are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [1.0.3] - 2026-09-05

### Added

- terraform-docs-generated interface documentation in README (Requirements/Providers/Inputs/Outputs) with a CI drift check.

## [1.0.2] - 2026-09-05

### Added

- CHANGELOG.md.

## [1.0.1] - 2026-09-04

### Added

- CI and release workflows (root validate uses mocked `aws.primary`/`aws.dr` providers).
- `.tflint.hcl` lint configuration.
- MIT LICENSE.
- README badges.
- `terraform` blocks in examples.
- Committed lock files.

### Changed

- AWS provider version constraint to `>= 5.0, < 7.0`.

## [1.0.0] - 2026-02-22

### Added

- Initial release.
- Multi-region EventBridge bus (primary + DR) via `aws.primary` and `aws.dr` provider aliases.
- EventBridge Schema Registry in primary region for event contract documentation.
- Event archive with configurable retention on both buses for replay capability.
- Bus resource policy for cross-account publisher access.
- Optional cross-region event routing — all primary bus events automatically replicated to DR bus.
- Full `terraform test` suite with mock providers.
- `examples/basic` and `examples/complete`.

> Historical releases are documented in [GitHub Releases](https://github.com/pomo-studio/terraform-aws-event-bus/releases).
