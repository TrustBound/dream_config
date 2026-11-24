# dream_config 2.0.0 Release Notes

**Release Date:** 2026-11-24

This release makes `dream_config` safe by default. The values that the platform sets win over a `.env` file. Every read function returns one typed error, so a typo in an optional number no longer falls back to the default, and an empty required value is an error. A bad `.env` file is a typed error with the path and the line number.

It is a major version: the four read functions and the load functions changed their types, and `load_dotenv()` no longer replaces a variable that is set. Read "Upgrading" before you upgrade. Version 1.1.0 was never released, and its changes are part of this release. The package also moved to its own repository.

## Key Highlights

- **The environment wins over the `.env` file**: `load_dotenv()` and `load_dotenv_from(path)` set only the variables that are not set yet. `load_dotenv_override()` and `load_dotenv_override_from(path)` let the file win
- **One error type for every read**: `get`, `get_int`, `get_required` and `get_required_int` return `ConfigError`: `NotSet(name)`, `NotAnInteger(name, value)` or `Empty(name)`. `describe(error)` gives the text for a log line
- **An empty required value is an error**: `get_required` and `get_required_int` return `Empty(name)` for `NAME=`
- **A typed error for a bad `.env` file**: `LoadError` has one variant for each cause, with the path and the line number. `describe_load_error(error)` gives the text
- **A byte order mark is skipped**: a `.env` file saved as UTF-8 with a byte order mark loads its first variable
- **A bad `.env` file is an error**: before, the load functions always returned `Ok(Nil)`
- **`get_bool` reads any letter case**: `tRUE` and `Yes` are now `True`, as the docs said
- **Its own `.env` reader and its own repository**: no dependency on `dot_env`, and the package lives at [TrustBound/dream_config](https://github.com/TrustBound/dream_config)

## What's New

### The Environment Wins Over the `.env` File

`load_dotenv()` and `load_dotenv_from(path)` set each variable of the file that is not set yet in the environment. A variable that is already set keeps its value, also when its value is an empty string, because the operating system treats a variable with an empty value as set. A `.env` file that reaches a production machine by mistake can no longer replace a value that the platform sets.

#### Load the .env file at startup <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_at_startup() -> Result(String, String) {
  // A missing .env file is not an error, a malformed one is
  use _ <- result.try(
    config.load_dotenv() |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
```

With `DATABASE_URL=postgres://db.internal:5432/myapp` in the environment and `DATABASE_URL=postgres://localhost:5432/myapp_dev` in `.env`, `database_url_at_startup()` returns `Ok("postgres://db.internal:5432/myapp")`.

### `load_dotenv_override` and `load_dotenv_override_from`

The two new functions keep the behavior from before: each variable of the file is set, and a value in the file replaces a variable that is set. Use them in development tools and tests that must use the file's values.

#### Let the .env file win <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_override.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_from_file() -> Result(String, String) {
  // The value in the .env file replaces a variable that is already set
  use _ <- result.try(
    config.load_dotenv_override()
    |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
```

With the same environment and file, `database_url_from_file()` returns `Ok("postgres://localhost:5432/myapp_dev")`.

### `ConfigError` and `describe`

`get`, `get_int`, `get_required` and `get_required_int` return `Result(_, ConfigError)`:

- `NotSet(name)`: the variable is not set
- `NotAnInteger(name, value)`: the value is not an integer
- `Empty(name)`: a required variable is set to an empty string

`get_int("PORT")` returns `Error(NotSet("PORT"))` when `PORT` is not set and `Error(NotAnInteger("PORT", "eighty"))` for `PORT=eighty`, so a default can apply only when the variable is not set. `describe(error)` gives `Required environment variable not set: PORT`, `Environment variable PORT must be an integer` and `Required environment variable is empty: DATABASE_URL`. The first two are the texts that the required functions returned before. `get_bool` is the same as before.

### `LoadError` and `describe_load_error`

The four load functions return `Result(Nil, LoadError)`. It has one variant for each cause:

- `FileNotFound(path)`: no file is at the path (not from `load_dotenv()` and `load_dotenv_override()`, because `.env` is optional)
- `FileNotReadable(path, reason)`: the file cannot be read, for example `permission denied`
- `FileNotUtf8(path)`: the file is not UTF-8
- `MissingEquals(path, line)`: a line has no `=`
- `EmptyName(path, line)`: the name before the `=` is empty
- `QuoteNotClosed(path, line, quote)`: a quoted value has no closing quote
- `TextAfterClosingQuote(path, line, quote)`: text follows a closing quote

`quote` is `DoubleQuote`, `SingleQuote` or `Backtick`. `describe_load_error(error)` gives the texts from before, for example `Cannot load .env file at .env: line 2: expected NAME=VALUE`.

### Its Own `.env` Reader

`dream_config` reads `.env` files with its own reader and no longer depends on `dot_env`. The file format is the same as before. Names are changed to upper case, as before.

### Its Own Repository

`dream_config` moved out of the Dream repository. It has its own version, its own changelog and its own release workflow. The package name on Hex and the module names are the same as before.

### Tested Docs and Guides

Each code example in the `dream_config/loader` doc comments is a tested snippet. The package has three guides in [`docs/guides/`](https://github.com/TrustBound/dream_config/tree/main/docs/guides), and HexDocs shows them. Each one walks through one task in steps, with failure cases, a test of your own code and common pitfalls:

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): load your settings into a typed record at startup, and stop with a clear message when one is missing, empty or wrong
- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): which value wins, the override functions, a secrets file, the file format, and the errors for a bad file
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md): defaults that apply only when a setting is not set, range checks, and the values that `get_bool` accepts

## Bug Fixes

### A Byte Order Mark Is Not Part of the First Name

A `.env` file saved as UTF-8 with a byte order mark (the bytes `EF BB BF`) kept the mark in the first variable name, so `get` could not find that variable. The reader now skips one byte order mark at the start of the file.

### The Load Functions Return Their Errors

`load_dotenv()` and `load_dotenv_from(path)` had the type `Result(Nil, String)`, and the docs said that a bad file is an error. But they always returned `Ok(Nil)`, and the problem went only to standard error. They now read and parse the file themselves and return a `LoadError`. A missing `.env` file is still `Ok(Nil)` for `load_dotenv()`. On an error, no variable from the file is set.

### `get_bool` Reads Any Letter Case

`get_bool` accepted only `true`, `True`, `TRUE`, `yes`, `YES` and `1`, although the docs said it is case-insensitive. It now accepts `true` and `yes` in any mix of upper and lower case, and `1`.

## Testing

- 218 tests run, 0 failed, 100% line coverage (137 of 137 lines), in about 1 second of test time and 2.6 seconds of wall time for `make test` (tests run one at a time), measured two times on an Apple M1 Max, 10 cores, 64 GB, macOS 26.5.1, OTP 29, Gleam 1.19.2, with a load average of about 6

## Upgrading

Update your dependencies:

```toml
[dependencies]
dream_config = ">= 2.0.0 and < 3.0.0"
```

Then run:

```bash
gleam deps update dream_config
```

### Migration Guide

Each step applies only in the case it names. The "before" code is the 1.0 code, and it does not compile with 2.0.0, so it is shown inline. The "after" code is a tested snippet.

#### 1. Your code reads the text of an error

Before, the required functions returned `Error(String)`, and code compared or printed that text, for example `Error(message) -> Error("Cannot start the application: " <> message)`. `get` and `get_int` returned `Error(Nil)`, and code matched `Error(Nil) -> default`.

After, match on the error value. A branch for each cause replaces a check of the text:

##### Match on the error value <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/release_migration_errors.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{Empty, NotAnInteger, NotSet} as config

pub fn port_hint() -> String {
  case config.get_required_int("PORT") {
    Ok(_) -> "PORT is valid"
    Error(NotSet(_)) -> "Set PORT, for example PORT=8080"
    Error(Empty(_)) -> "PORT is empty"
    Error(NotAnInteger(_, value)) -> "PORT is not a number: " <> value
  }
}
```

Where you need the text, call `config.describe(error)`. It gives the same text as before for `NotSet` and `NotAnInteger`:

##### Read a required value <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_get_required.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config

pub fn database_url() -> Result(String, String) {
  case config.get_required("DATABASE_URL") {
    Ok(url) -> Ok(url)
    Error(error) ->
      Error("Cannot start the application: " <> config.describe(error))
  }
}
```

For the load functions, call `config.describe_load_error(error)`, for example `config.load_dotenv() |> result.map_error(config.describe_load_error)` in a `result.try` chain. Replace `Error(Nil)` in a match on `get` or `get_int` with `Error(NotSet(_))`, and decide what `NotAnInteger` means for `get_int`.

#### 2. Your code relies on the `.env` file replacing variables that are set

Before, `use _ <- result.try(config.load_dotenv())` set every variable of the file, and a value in the file replaced a variable that was set.

After, `load_dotenv()` keeps a variable that is set. Where the file must win, call `load_dotenv_override()`, or `load_dotenv_override_from(path)` for a file at a path:

##### Let the .env file win <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_override.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_from_file() -> Result(String, String) {
  // The value in the .env file replaces a variable that is already set
  use _ <- result.try(
    config.load_dotenv_override()
    |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
```

If you load two files with `load_dotenv_from` and want the second file to win, load it first. The first value for a name now wins.

#### 3. A required setting can be empty

Before, `config.get_required("LOG_PREFIX")` returned `Ok("")` for `LOG_PREFIX=`.

After, `get_required` returns `Error(Empty("LOG_PREFIX"))` for it. When the variable must be set but can be empty, read it with `get`:

##### Read a setting that can be empty <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/release_migration_may_be_empty.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{type ConfigError} as config

pub fn log_prefix() -> Result(String, ConfigError) {
  // LOG_PREFIX must be set, but an empty prefix is a valid value
  config.get("LOG_PREFIX")
}
```

`log_prefix()` returns `Ok("")` for `LOG_PREFIX=` and `Error(NotSet("LOG_PREFIX"))` when the variable is not set.

#### 4. Your `.env` file starts with a byte order mark

Before, the first variable of the file was not found, and the fix was to save the file without the mark.

After, the reader skips the mark. You need no code change.

#### 5. Your code ignores the result of a load function

A bad file is now an `Error`. Handle it in your `result.try` chain, as in step 1.

#### 6. You call `load_dotenv_from(path)` with a path that may not exist

Check for the file first, or treat `Error(FileNotFound(_))` as "no file".

#### 7. Your `.env` file has a line with no `=`, or text after a closing quote

A line with no `=` used to be joined with the next line into one name. As the last line, it stopped the whole file from loading with no error. Text after a closing quote was accepted. Both are now an error. Correct the line, or make it a comment with `#`.

#### 8. Your code relies on `get_bool` returning `False` for `tRUE` or `Yes`

`get_bool` now returns `True` for those values.

## Documentation

- [dream_config](https://hexdocs.pm/dream_config) - v2.0.0
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md)
- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md)
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md)
- [Changelog](https://github.com/TrustBound/dream_config/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_config/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_config/blob/main/CONTRIBUTING.md)
