# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.1.0] - 2020-07-24

### Changed

- Switched admin password from start argument to user-seed.conf
- Changes to ensure systemd option works
- Cleanup of unnecessary file declarations (etc/apps, etc/system/local)
- Updated spec tests

## [v2.0.1] - 2020-07-21

### Added

- Updated changelog format

## [v2.0.0]

### Added

- Updated to create indexes.conf on cluster master
- Added examples and code to create SmartStore configs

## [v1.9.2]

### Changed

- cleanup/re-order documentation
- pdk update

## [v1.9.1]

### Added

- Improved documentation
- Vagrant example

## [v1.9.0]

### Fixed

- cleanup shcluster initialization - now both indexer cluster and search clusters deploy in fuctional state

## [v1.8.3]

### Changed

- default to "Trial" license group
- add OS specific init providers
- cleanup input template for splunktcp/splunktcp-ssl inputs
- increase line length for rubocop

### Fixed

- close #4
