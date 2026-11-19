<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>Type-safe configuration management for Gleam applications</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_config">
    <img src="https://img.shields.io/hexpm/v/dream_config" alt="Hex Package">
  </a>
  <a href="https://github.com/TrustBound/dream_config/releases">
    <img src="https://img.shields.io/github/v/release/TrustBound/dream_config?label=Release" alt="Latest Release">
  </a>
  <a href="https://hexdocs.pm/dream_config">
    <img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs">
  </a>
  <a href="https://github.com/TrustBound/dream_config/actions/workflows/ci.yml?query=branch%3Amain">
    <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_config/badges/coverage.json" alt="Coverage">
  </a>
  <a href="https://github.com/TrustBound/dream_config/blob/main/LICENSE.md">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  </a>
  <a href="https://gleam.run">
    <img src="https://img.shields.io/badge/gleam-%E2%9C%A8-ffaff3" alt="Gleam">
  </a>
</div>

<br />

## What is dream_config?

A standalone module for loading configuration from environment variables and `.env` files. Built with the same quality standards as [Dream](https://github.com/TrustBound/dream), but completely independent—use it in any Gleam project.

## Features

- ✅ Load from environment variables or `.env` files
- ✅ Type-safe with `Result` types (no silent failures)
- ✅ Support for strings, integers, and booleans
- ✅ Required vs optional configuration values
- ✅ Zero dependencies on Dream or other frameworks

## Installation

```bash
gleam add dream_config
```

## Quick Start <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_quick_start.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub type Settings {
  Settings(database_url: String, port: Int, debug_mode: Bool, api_key: String)
}

pub fn load_settings() -> Result(Settings, String) {
  // Load .env file (optional, a missing file is not an error)
  use _ <- result.try(config.load_dotenv())

  // Get required configuration
  use database_url <- result.try(config.get_required("DATABASE_URL"))
  use port <- result.try(config.get_required_int("PORT"))

  // Get optional configuration with defaults
  let debug_mode = config.get_bool("DEBUG")
  let api_key = config.get("API_KEY") |> result.unwrap("default-key")

  Ok(Settings(database_url:, port:, debug_mode:, api_key:))
}
```

## Usage

### Loading `.env` Files

`load_dotenv()` reads `.env` in the current directory. A missing `.env` file is not an error, so the same code runs where the variables are set directly. `load_dotenv_from(path)` reads the file at `path`, and a missing file is an error.

Both return `Error(String)` with the path and the reason when the file cannot be read (for example no permission, a directory, or not UTF-8), or when a line is not valid. The message gives the line number, for example `Cannot load .env file at .env: line 2: expected NAME=VALUE`. On an error, no variable from the file is set.

The format is `NAME=VALUE`, one variable on each line. Lines that start with `#` are comments, and values can be in double quotes, single quotes or backticks. Names are changed to upper case.

#### Load two files <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_load_env_files.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn load_env_files(env_file_path: String) -> Result(Nil, String) {
  // Load from default location (current directory)
  use _ <- result.try(config.load_dotenv())

  // Load from specific path, for example "/etc/myapp/.env"
  config.load_dotenv_from(env_file_path)
}
```

### Required Values

Use `get_required*` functions for values your application cannot run without:

#### Load required settings <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_required_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub type AppConfig {
  AppConfig(database_url: String, port: Int)
}

pub fn load_config() -> Result(AppConfig, String) {
  use database_url <- result.try(config.get_required("DATABASE_URL"))
  use port <- result.try(config.get_required_int("PORT"))

  Ok(AppConfig(database_url: database_url, port: port))
}
```

### Optional Values

Use `get*` functions for values with sensible defaults:

#### Read optional settings <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_optional_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/option
import gleam/result

pub fn read_optional_values() -> #(option.Option(String), Int) {
  let api_key = config.get("API_KEY") |> option.from_result

  // Default to 3000
  let port = config.get_int("PORT") |> result.unwrap(3000)

  #(api_key, port)
}
```

### Boolean Values

The `get_bool()` function treats these as `True`, in any mix of upper and lower case (for example `TRUE`, `tRUE` or `Yes`):
- `"true"`
- `"1"`
- `"yes"`

Everything else (including unset, and values with spaces around them) is `False`:

#### Pick a log level from DEBUG <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_boolean_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config

pub fn log_level() -> String {
  let debug_mode = config.get_bool("DEBUG")
  case debug_mode {
    True -> "debug"
    False -> "info"
  }
}
```

## API Reference

### Loading `.env` Files

- `load_dotenv() -> Result(Nil, String)` - Load from default location (a missing file is `Ok(Nil)`)
- `load_dotenv_from(path: String) -> Result(Nil, String)` - Load from specific path (a missing file is an error)

### Getting Values

- `get_required(name: String) -> Result(String, String)` - Required string
- `get(name: String) -> Result(String, Nil)` - Optional string
- `get_required_int(name: String) -> Result(Int, String)` - Required integer
- `get_int(name: String) -> Result(Int, Nil)` - Optional integer
- `get_bool(name: String) -> Bool` - Boolean (defaults to `False`)

## Design Principles

dream_config follows Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md) and [contributing guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

## About Dream

This module was originally built for the [Dream](https://github.com/TrustBound/dream) web toolkit, but it's completely standalone and can be used in any Gleam project. It follows Dream's design principles and will be maintained as part of the Dream ecosystem.

## Contributing

See the [Contributing Guide](https://github.com/TrustBound/dream_config/blob/main/CONTRIBUTING.md). The coding and testing standards are Dream's: see [Dream's contributing guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md).

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_config/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
