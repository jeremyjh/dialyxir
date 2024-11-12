# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

Versions follow [Semantic Versioning 2.0](https://semver.org/spec/v2.0.0.html)

## Unreleased changes post [1.4.4]

   ### Fixed
   - Crash when default ignore file missing and custom file specified

## [1.4.3] - 2023-12-28
  ### Fixed
  - Warnings with line & column.
  - Formatting of `:record_match` warning.

## [1.4.2] - 2023-10-21

  ### Changed
  - Revert minimum required Elixir version back to 1.6.
  - Improved performance in calculating Umbrella dependencies.

## [1.4.1] - 2023-08-30

  ### Changed
  - Bump minimum required Elixir version to 1.12.

## [1.4.0] - 2023-08-27

### Added
  - --quiet-with-result flag.

### Changed
  - (docs) Improved caching behaviour in example templates.

### Fixed
  - Erroneous "DEPENDENCY MISSING" message in Elixir 1.15.
  - Handle transitive optional dependencies in Elixir 1.15.

## [1.3.0] - 2023-04-08

### Added
  - Elixir 1.15 support.
  - Support for warning `:callback_not_exported`.

### Changed
  - Several improvements to documentation, particularly Github CI documentation.

### Removed
  - Support for `:race_conditions` flag which was [removed from Erlang](https://github.com/erlang/otp/pull/5502).

### Fixed
  - Crash when `mix.lock` is missing.

## [1.2.0] - 2022-07-20
### Added
  - "github" formatter.

## [1.1.0] - 2021-02-18

### Added
  - Configuration option to set the project's PLT path: `:plt_local_path`.
  - Project configuration setting to exclude files based on a regex: `:exclude_files`.
  - `explain` text for `:missing_range` warning.

### Fixed

  - Fixes and improvements to README and documentation.
  - Fixed `mix.lock` hash stability. Will cause a recheck of PLTs on first usage in each project.

### Changed
  - Improved wording of argument mismatch warnings.

## [1.0.0] - 2020-03-16

### Changed
 - Deprecated `plt_add_deps` modes: `transitive`, `project`. Use `app_tree` and `apps_direct` instead.
 - Moved Explain text to `@moduledoc`.

### Fixed
 - Warning pretty printing and message fixes/improvements.
 - Prevent crash when short_format fails.
 - Ensure path to PLT target directory exists.
 - Bumped required `erlex` for formatting fix.

## [1.0.0-rc.7] - 2019-09-21

### Changed
  - Halt with a non-zero exit status by default; swap `--halt-exit-status` for `--ignore-exit-status`.

### Added
  - OTP 22 compatibility in `:fun_app_args` warning.
  - Support for `:map_update` warning.
  - Report elapsed time in building/updating PLT.

### Fixed
  - Warnings for protocols not implemented for built-in types.
  - Fix ANSI disabling - its now actually possible to disable ANSI.
  - Improve wording and fix grammar/punctuation in many warnings.

## [1.0.0-rc.6] - 2019-04-02

### Fixed
  - Improved warning formatting for unknown types/functions

## [1.0.0-rc.5] - 2019-03-26

### Added
  - `plt_ignore_apps` option to ignore specific dependencies

### Removed
  - Removed instructions for global (mix archive) installation. Installing as a per-project
    mix dependency is the only supported method.

### Changed
  - Updated many short warning formats to be shorter and more consistent

### Fixed
  - Pretty print for a few warnings
  - Improved wording in explanations
  - Fix raw format and add all formats to CI

## [1.0.0-rc.4] - 2018-10-31

### Added
  - Regex support in Elixir Term Format ignore entries.

### Changed
  - Extracted parsing / pretty printing to separate library: erlex.

### Fixed
  - Parsing, formatting fixes.

## [1.0.0-rc.3] - 2018-06-30

### Fixed
  - Parsing, formatting fixes.
  - OptionParser fixes - remove unimplemented options.

## [1.0.0-rc.1-2] - 2018-06-14

### Fixed
 - Exception handling around formatter.
 - hex package file list.

## [1.0.0-rc.0] - 2018-06-13

### Added
  - Parsing Erlang terms from `dialyzer` warnings and pretty-printing as Elixir terms.
  - Format options: short, raw, dialxyir dialyzer.
  - Ignore rules can be supplied in Elixir term format.

## [0.5.1] - 2017-07-29

### Added
  - Elixir 1.5 support.

## [0.5.0] - 2017-02-21

### Changed

  - Use `:dialyzer` API to run analysis rather than shelling the dialyzer CLI
