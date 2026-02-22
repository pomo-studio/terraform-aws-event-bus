# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-22

### Added
- Initial release
- Multi-region EventBridge bus (primary + DR) via `aws.primary` and `aws.dr` provider aliases
- EventBridge Schema Registry in primary region for event contract documentation
- Event archive with configurable retention on both buses for replay capability
- Bus resource policy for cross-account publisher access
- Optional cross-region event routing — all primary bus events automatically replicated to DR bus
- Full `terraform test` suite with mock providers
- `examples/basic` and `examples/complete`

[1.0.0]: https://github.com/pomo-studio/terraform-aws-event-bus/releases/tag/v1.0.0
