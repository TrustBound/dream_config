# Required values

This guide shows how to read configuration values that your application cannot run without. A missing or invalid value is an `Error(String)` that names the variable.

## Load required settings

Use the `get_required*` functions for values your application cannot run without:

### Load required settings <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_required_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Errors

- `get_required` returns `Error(String)` when the variable is not set. The message includes the variable name.
- `get_required_int` returns `Error(String)` when the variable is not set or is not a valid integer. Use it for required numeric configuration such as port numbers or timeouts.

## Functions

- `get_required(name: String) -> Result(String, String)`: required string
- `get_required_int(name: String) -> Result(Int, String)`: required integer

## See also

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): install the package and load settings at startup
- [Load .env files](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): load variables from a `.env` file
- [Optional values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/optional-values.md): read values that have defaults
- [Boolean values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/boolean-values.md): read a variable as `True` or `False`
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
