<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>Type-safe configuration management for Gleam applications</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_config"><img src="https://img.shields.io/hexpm/v/dream_config" alt="Hex Package"></a>
  <a href="https://github.com/TrustBound/dream_config/releases"><img src="https://img.shields.io/github/v/release/TrustBound/dream_config?label=Release" alt="Latest Release"></a>
  <a href="https://hexdocs.pm/dream_config"><img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs"></a>
  <a href="https://github.com/TrustBound/dream_config/actions/workflows/ci.yml?query=branch%3Amain"><img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_config/badges/coverage.json" alt="Coverage"></a>
  <a href="https://github.com/TrustBound/dream_config/blob/main/LICENSE.md"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://gleam.run"><img src="https://img.shields.io/badge/gleam-%E2%9C%A8-ffaff3" alt="Gleam"></a>
</div>

<br />

## What is dream_config?

A standalone module for loading configuration from environment variables and `.env` files. It is built with the same quality standards as [Dream](https://github.com/TrustBound/dream), but it is completely independent. Use it in any Gleam project.

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

## Quick Start

### Load settings at startup <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_quick_start.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/docs/guides/getting-started.md#load-settings-at-startup-"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

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

## Guides

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): install the package and load settings at startup
- [Load .env files](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): load variables from a `.env` file, the file format, and the errors
- [Required values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/required-values.md): read values the application cannot run without
- [Optional values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/optional-values.md): read values that have defaults
- [Boolean values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/boolean-values.md): read a variable as `True` or `False`

## API Reference

The full API reference is on [HexDocs](https://hexdocs.pm/dream_config). Each guide lists the functions it uses.

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
