# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project aims to adhere to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added <!-- for new features. -->
### Changed <!-- for changes in existing functionality. -->
### Deprecated <!-- for soon-to-be removed features. -->
### Removed <!-- for now removed features. -->
### Fixed <!-- for any bug fixes. -->

## [1.0.0] - 2022-02-10
### Added
- Added testing support for Ruby 2.7, 3.0, and 3.1
- Added testing support for ActiveModel 5.2-7.0
### Changed
- Switched from TravisCI to GitHub Actions
- Requiring MFA for pushing to rubygems.org
- Upgraded to the latest in linter technology
### Removed
- Drops support for ActiveModel/ActiveSupport < 5.2
- Drops support for Ruby < 2.6.5

## [0.1.0] - 2022-02-10
### Added
- Adds a class-level helper method for accessing all possible state values. It
  automatically defines itself as the pluralized version of the name of the
  steady_state attribute, and can be disabled by passing `states_getter:
  false`. Special thanks to @agirlnamedsophia for the contribution!

## [0.0.1] - 2018-10-23
### Added
- The initial open source release! See the README for all available features.


[1.0.0]: https://github.com/betterment/uncruft/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/betterment/uncruft/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/betterment/uncruft/releases/tag/v0.0.1
