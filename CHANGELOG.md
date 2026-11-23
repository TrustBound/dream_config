# Changelog

All notable changes to `dream_config` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - Unreleased

Version 1.1.0 was never released. Its changes are part of 2.0.0.

### Breaking
- `load_dotenv()` and `load_dotenv_from(path)` set only the variables that
  are not set yet in the environment. A variable that is already set keeps
  its value, also when its value is an empty string. Before, a value in the
  file replaced a variable that was set. The new functions
  `load_dotenv_override()` and `load_dotenv_override_from(path)` keep the
  old behavior: the file wins. With both, the last line of the file wins
  when a name is on more than one line.
- `get`, `get_int`, `get_required` and `get_required_int` return
  `Result(_, ConfigError)`, with `NotSet(name)`,
  `NotAnInteger(name, value)` and `Empty(name)`. Before, `get` and `get_int`
  returned `Error(Nil)`, and the required functions returned
  `Error(String)`. The new function `describe(error)` gives the text of the
  messages from before, for example
  `Required environment variable not set: PORT`. `get_bool` is the same as
  before.
- `get_int` returns `NotSet(name)` for a variable that is not set and
  `NotAnInteger(name, value)` for a value that is not an integer. Before,
  both were `Error(Nil)`, so a default hid a typo.
- `get_required` and `get_required_int` return `Empty(name)` for a variable
  that is set to an empty string. Before, `get_required` returned `Ok("")`.
  `describe(Empty("DATABASE_URL"))` is
  `Required environment variable is empty: DATABASE_URL`. `get` still
  returns `Ok("")`.
- The four load functions return `Result(Nil, LoadError)`, with one variant
  for each cause: `FileNotFound(path)`, `FileNotReadable(path, reason)`,
  `FileNotUtf8(path)`, `MissingEquals(path, line)`, `EmptyName(path, line)`,
  `QuoteNotClosed(path, line, quote)` and
  `TextAfterClosingQuote(path, line, quote)`, where `quote` is
  `DoubleQuote`, `SingleQuote` or `Backtick`. The new function
  `describe_load_error(error)` gives the text of the messages from before,
  for example `Cannot load .env file at .env: line 2: expected NAME=VALUE`.

### Fixed
- A `.env` file that starts with a byte order mark (the bytes `EF BB BF`)
  kept the mark in the first variable name, so `get` could not find that
  variable. The reader now skips one byte order mark at the start of the
  file.
- `load_dotenv()` and `load_dotenv_from(path)` always returned `Ok(Nil)`,
  although their type is `Result(Nil, String)` and the docs said that a bad
  file is an error. The `dot_env` load functions return `Nil` and only print
  the problem to standard error, so the error was lost. Both functions now
  read and parse the file themselves and return an error with the path and
  the reason (a `LoadError`, see "Breaking"). The texts of
  `describe_load_error` are:
  - the file cannot be read (no permission, a directory, or not UTF-8), for
    example `Cannot load .env file at .env: permission denied`
  - a line is not valid (no `=`, an empty name, a quote that is not closed,
    or text after a closing quote), with its line number, for example
    `Cannot load .env file at .env: line 2: expected NAME=VALUE`
  - `load_dotenv_from(path)` only: the file does not exist, for example
    `Cannot load .env file at /etc/myapp/.env: the file does not exist`

  A missing `.env` file is still `Ok(Nil)` for `load_dotenv()`, because that
  file is optional where the variables are set directly. On an error, no
  variable from the file is set. The file format is the same as before
  (names are changed to upper case).
- `get_bool` accepted only `true`, `True`, `TRUE`, `yes`, `YES` and `1`,
  although the docs said it is case-insensitive. It now accepts `true` and
  `yes` in any mix of upper and lower case (for example `tRUE` and `Yes`),
  and `1`.

### Changed
- Moved to its own repository
- `dream_config` no longer depends on `dot_env`. It reads `.env` files with
  its own reader.
- Each code example in the `dream_config/loader` doc comments is now a
  tested snippet, and the examples are valid Gleam.
- The package has three guides in `docs/guides/`, and HexDocs shows them:
  Getting started (load settings at startup and stop with a clear message),
  Use a .env file in development, and Read optional settings, numbers and
  flags. Each guide walks through one task in steps, with failure cases, a
  test of your own code and common pitfalls. Every code example in them is
  a tested snippet. The README is short and links to them.

### Upgrading
- Match on `ConfigError` and `LoadError` instead of the text of a message.
  Where you need the text, call `describe(error)` or
  `describe_load_error(error)`, for example
  `config.get_required("DATABASE_URL") |> result.map_error(config.describe)`.
- If you relied on the `.env` file replacing variables that are set, call
  `load_dotenv_override()` or `load_dotenv_override_from(path)`.
- If you load two files and want the second one to win, load it first, or
  load it with `load_dotenv_override_from(path)`.
- If a required setting can be empty, read it with `get(name)` instead of
  `get_required(name)`.
- Replace `Error(Nil)` in matches on `get` and `get_int` with
  `Error(NotSet(_))`, and handle `NotAnInteger` for `get_int`.
- If your code called `load_dotenv()` or `load_dotenv_from(path)` and
  ignored the result, a bad file is now an `Error`. Handle it, for example
  with `config.load_dotenv() |> result.map_error(config.describe_load_error)`
  in a `result.try` chain.
- If you call `load_dotenv_from(path)` with a path that may not exist, check
  for the file first or treat the `Error` as "no file".
- A `.env` line with no `=` used to be joined with the next line into one
  name, or, as the last line, stopped the whole file from loading with no
  error. It is now an error: fix the line or make it a comment with `#`.
- Text after a closing quote on the same line (other than a `#` comment)
  is now an error.
- `get_bool` now returns `True` for values such as `tRUE` or `Yes` that it
  returned `False` for before.

### Testing

- 218 tests run, 0 failed, 100% line coverage (137 of 137 lines), in about 1 second of test time and 2.6 seconds of wall time for `make test` (tests run one at a time), measured two times on an Apple M1 Max, 10 cores, 64 GB, macOS 26.5.1, OTP 29, Gleam 1.19.2, with a load average of about 4

## [1.0.2] - 2025-11-21

### Changed
- Added HexDocs documentation badge to README

## [1.0.1] - 2025-11-22

### Fixed
- Fixed logo display on hex.pm by using full GitHub URL
- Added Dream logo to README

## [1.0.0] - 2025-11-21

### Added
- Initial stable release
- `load_dotenv()` - Load `.env` file from default location
- `load_dotenv_from(path)` - Load `.env` file from specific path
- `get_required(name)` - Get required environment variable
- `get(name)` - Get optional environment variable
- `get_required_int(name)` - Get required integer environment variable
- `get_int(name)` - Get optional integer environment variable
- `get_bool(name)` - Get boolean environment variable

