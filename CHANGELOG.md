# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4] - 2026-04-28

### Added

- Added `init-nordlynx-resolvconf` s6 service to initialize `openresolv` and take control of `resolv.conf`. Upstream
  scoped their equivalent workaround to server mode only (PR #401), which broke DNS in client mode since openresolv
  still needs to register a control interface before WireGuard brings the tunnel up.

### Changed

- Bumped Alpine base image to 3.23

### Removed

- Removed outdated known issue section from README.md
- Removed Docker Hub publishing; image is now only pushed to GHCR (`ghcr.io/arkandias/nordlynx`)

### Fixed

- Scoped 'check-upstream-updates' workflow permissions to read-only with explicit issue write access

## [1.3] - 2025-01-20

### Added

- Known issue note for iptables in v1.2 to README

### Fixed

- Fixed branch name in Check Upstream Updates workflow
- Updated iptables symlinks path for Alpine 3.21 compatibility

### Changed

- Issue's title and body in upstream check workflow

## [1.2] - 2025-01-02

### Added

- Concurrency in Docker Image CI workflow
- Dependabot for GitHub Actions
- Workflow to check upstream updates

### Changed

- Updated documentation

## [1.1] - 2024-12-06

### Added

- IPv6 support and interface details in documentation
- Firewall rules for local network interfaces
- DNS request allowlisting and connection management
- Private key retrieval and allowlist configuration rules

### Changed

- Synced with upstream
- Improved logging messages
- Updated local networks routing
- Updated temporary rules for DNS and private key retrieval
- Updated documentation
- Renamed services to follow linuxserver naming convention

## [1.0] - 2024-12-03

### Added

- Initial release of Docker NordLynx container
- S6 overlay for service management
- Firewall rules for secure VPN operation
- Local network interface detection
- Allowlist configuration support
- Private key retrieval functionality
