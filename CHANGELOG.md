# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.1.4] - 2020-08-04

### Changed

- Re-ordered license page

## [v2.1.3] - 2020-07-30

### Added

- spec test for Debian install

### Fixed

- Typos in service.pp affecting Debian systems
- Legacy facts replaced with structured facts

## [v2.1.2] - 2020-07-29

### Fixed

- splunk_cwd fact not popluating on some OSes

## [v2.1.1] - 2020-07-29

### Fixed

- Removed unncessary require from auth.pp that caused an error when authentication was defined and the installed version was higher than the version defined

## [v2.1.0] - 2020-07-24

### Changed

- Switched admin password from start argument to user-seed.conf
- Changes to ensure systemd option works
- Cleanup of unnecessary file declarations (etc/apps, etc/system/local)
- Updated spec tests
- Closed #17 - Splunk not upgrading when stopped

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
