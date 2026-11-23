# Getting started

This guide shows how to add dream_config to a Gleam project and load the settings of an application at startup.

## Install

Add the package as a dependency:

```bash
gleam add dream_config
```

dream_config has no dependency on Dream or other frameworks. You can use it in any Gleam project.

## Load settings at startup

All functions return `Result` types, so you must handle missing or invalid values. Use the `get_required*` functions for values that must be present, and the `get*` functions for optional values.

The example loads the `.env` file, reads two required values, and reads two optional values with defaults.

### Load settings at startup <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_quick_start.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## See also

- [Load .env files](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): load variables from a `.env` file
- [Required values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/required-values.md): read values the application cannot run without
- [Optional values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/optional-values.md): read values that have defaults
- [Boolean values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/boolean-values.md): read a variable as `True` or `False`
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
