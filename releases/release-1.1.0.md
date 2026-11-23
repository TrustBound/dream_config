# dream_config 1.1.0 Release Notes

**Release Date:** not released yet (draft)

This release makes `dream_config` tell you when a `.env` file is bad. Before, `load_dotenv()` and `load_dotenv_from(path)` always returned `Ok(Nil)`, and the problem went only to standard error.

It is a minor version: no function changed its type. But two functions now return errors that they hid before. Read "Upgrading" before you upgrade. The package also moved to its own repository.

## Key Highlights

- **A bad `.env` file is an error**: `load_dotenv()` and `load_dotenv_from(path)` return `Error(String)` with the path and the reason
- **`get_bool` reads any letter case**: `tRUE` and `Yes` are now `True`, as the docs said
- **Its own `.env` reader**: the package no longer depends on `dot_env`
- **Its own repository**: `dream_config` now lives at [TrustBound/dream_config](https://github.com/TrustBound/dream_config), with its own version and its own releases

## What's New

### Its Own `.env` Reader

`dream_config` reads `.env` files with its own reader and no longer depends on `dot_env`. The file format is the same as before. Names are changed to upper case, as before.

### Its Own Repository

`dream_config` moved out of the Dream repository. It has its own version, its own changelog and its own release workflow. The package name on Hex and the module names are the same as before.

### Tested Docs

Each code example in the `dream_config/loader` doc comments is now a tested snippet, and the examples are valid Gleam.

## Bug Fixes

### `load_dotenv` and `load_dotenv_from` Return Their Errors

Both functions have the type `Result(Nil, String)`, and the docs said that a bad file is an error. But they always returned `Ok(Nil)`. They now read and parse the file themselves and return `Error(String)` with the path and the reason:

- The file cannot be read (no permission, a directory, or not UTF-8), for example `Cannot load .env file at .env: permission denied`
- A line is not valid (no `=`, an empty name, a quote that is not closed, or text after a closing quote), with its line number, for example `Cannot load .env file at .env: line 2: expected NAME=VALUE`
- `load_dotenv_from(path)` only: the file does not exist, for example `Cannot load .env file at /etc/myapp/.env: the file does not exist`

A missing `.env` file is still `Ok(Nil)` for `load_dotenv()`, because that file is optional where the variables are set directly. On an error, no variable from the file is set.

#### Load the `.env` file at startup <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/doc_load_dotenv.gleam#L5-L12"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_at_startup() -> Result(String, String) {
  // A missing .env file is not an error, a malformed one is
  use _ <- result.try(config.load_dotenv())
  config.get_required("DATABASE_URL")
}
```

### `get_bool` Reads Any Letter Case

`get_bool` accepted only `true`, `True`, `TRUE`, `yes`, `YES` and `1`, although the docs said it is case-insensitive. It now accepts `true` and `yes` in any mix of upper and lower case, and `1`.

## Testing

- 61 tests run, 0 failed, in about 0.4 seconds (Apple M1 Max, 10 cores, 64 GB, macOS 26.5.1, OTP 29, Gleam 1.17.0)

## Upgrading

Update your dependencies:

```toml
[dependencies]
dream_config = ">= 1.1.0 and < 2.0.0"
```

Then run:

```bash
gleam deps update dream_config
```

### Migration Guide

No function changed its type. Each step applies only in the case it names.

#### 1. Your code ignores the result of `load_dotenv()` or `load_dotenv_from(path)`

A bad file is now an `Error`. Handle it, for example with `use _ <- result.try(config.load_dotenv())`.

#### 2. You call `load_dotenv_from(path)` with a path that may not exist

Check for the file first, or treat the `Error` as "no file".

#### 3. Your `.env` file has a line with no `=`

Such a line used to be joined with the next line into one name. As the last line, it stopped the whole file from loading with no error. It is now an error. Correct the line, or make it a comment with `#`.

#### 4. Your `.env` file has text after a closing quote

Text after a closing quote on the same line is now an error, unless it is a `#` comment.

#### 5. Your code relies on `get_bool` returning `False` for `tRUE` or `Yes`

`get_bool` now returns `True` for those values.

## Documentation

- [dream_config](https://hexdocs.pm/dream_config) - v1.1.0
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
- [Changelog](https://github.com/TrustBound/dream_config/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_config/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_config/blob/main/CONTRIBUTING.md)
