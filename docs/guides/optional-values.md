# Optional values

This guide shows how to read configuration values that have sensible defaults or are truly optional. A missing value is `Error(Nil)`, and you choose the default.

## Read optional settings

Use the `get*` functions for values with sensible defaults:

### Read optional settings <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_optional_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Errors

- `get` returns `Error(Nil)` when the variable is not set.
- `get_int` returns `Error(Nil)` when the variable is not set or is not a valid integer.

## Functions

- `get(name: String) -> Result(String, Nil)`: optional string
- `get_int(name: String) -> Result(Int, Nil)`: optional integer

## See also

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): install the package and load settings at startup
- [Load .env files](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): load variables from a `.env` file
- [Required values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/required-values.md): read values the application cannot run without
- [Boolean values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/boolean-values.md): read a variable as `True` or `False`
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
