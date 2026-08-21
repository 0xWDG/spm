# Changelog

Notable user-facing changes are documented in this file. The project follows [Semantic Versioning](https://semver.org/).

## Unreleased

## 0.0.2 - 2026-08-21

### Added

- Colored, terminal-aware command help and global JSON, quiet, and no-color output options.
- Version, shell completion, doctor, diff, package uninstall, and configuration validation commands.
- Selective Xcode package products and targets with transactional dry-run support.
- Package creation, build platform, and header path-selection options.
- Public repository documentation, contribution guidance, and automated verification.

### Changed

- Extracted reusable command behavior into the `SPMCore` library.
- Adopted Swift 6.0 as the package tools-version and compatibility baseline.

### Fixed

- Child processes now drain standard output and error concurrently and enforce timeouts.
- Multi-file writes roll back when a transaction cannot be completed.
