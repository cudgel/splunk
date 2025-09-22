# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.3.1] - 2025-09-21

### Changed

- Migrated CI/CD from Travis CI to GitHub Actions
- Updated deployment workflow to use Puppet Forge API key authentication
- Improved build performance with bundler caching and matrix builds

### Added

- GitHub Actions workflow for continuous integration
- GitHub Actions workflow for automated Puppet Forge deployment
- Support for MFA-enabled Puppet Forge accounts

## [v2.3.0] - 2025-09-21

### Added

- Support for Splunk 9.4+ package naming scheme (linux-amd64 vs Linux-x86_64)
- Improved version comparison logic for package naming
- Enhanced hostname fact support

### Changed

- Updated ACL management to use simpler, more reliable ACL testing
- Improved fact handling to use manifest files instead of binary detection
- Enhanced architecture detection and handling
- Updated spec tests to match new package naming conventions
- Refactored variable handling to disambiguate facts from variables

### Fixed

- Fixed test failures related to file resource naming mismatches
- Fixed ACL variable reference issue when splunk class is not available
- Fixed package file removal logic during version changes to handle naming scheme differences
- Fixed architecture variable references and selinux fact usage
- Corrected file path expectations in unit tests
- Improved error handling in ACL define when group parameter is missing

## [v2.2.2] - 2025-04-25

### Changed

- Updated fact collection to use manifest instead of binary for version detection

### Fixed

- Improved reliability of splunk_version fact determination

## [v2.2.1] - 2025-01-08

### Changed

- Version bump for metadata updates

## [v2.2.0] - 2025-01-08

### Added

- Enhanced puppet-lint configuration
- Improved Rakefile with additional linting tasks
- Better Gemfile dependency management

### Changed

- Updated metadata.json with improved dependency constraints
- Refactored multiple manifest files for better code quality
- Improved spec test structure and reduced redundancy
- Enhanced deployment.pp, fetch.pp, and service.pp implementations
- Updated input.pp and install.pp with better error handling

### Fixed

- Fixed linting issues across multiple manifest files
- Improved code quality and consistency
- Fixed spec test reliability

## [v2.1.9] - 2025-01-06

### Added

- ACL testing before applying ACLs to prevent errors
- Improved service file handling
- PDK updates for better development experience

### Changed

- Simplified ACL implementation with more reliable testing
- Enhanced fact handling and variable disambiguation
- Improved architecture detection logic
- Updated OS-specific configuration handling
- Better selinux fact integration

### Fixed

- Fixed ACL application logic to be more robust
- Improved variable references to prevent conflicts
- Fixed architecture detection issues
- Enhanced fact collection reliability

## [v2.1.8] - 2023-09-22

### Fixed

- added insecure flags to wget to deal with weak cert on downloads.splunk.com

## [v2.1.7] - 2023-07-20

### Fixed

- Removed stdlib max version

## [v2.1.6] - 2023-07-18

### Fixed

- Initial service start with systemd


## [v2.1.5] - 2021-02-10

### Changed

- Fix regression not populating password seed because fact was populating without Splunk running

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
