# Boolean values

This guide shows how to read an environment variable as a boolean. `get_bool` never fails: a variable that is not set is `False`.

## Pick a log level from DEBUG

The `get_bool()` function treats these as `True`, in any mix of upper and lower case (for example `TRUE`, `tRUE` or `Yes`):

- `"true"`
- `"1"`
- `"yes"`

Everything else (including unset, and values with spaces around them) is `False`:

### Pick a log level from DEBUG <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_boolean_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Functions

- `get_bool(name: String) -> Bool`: boolean (defaults to `False`)

## See also

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): install the package and load settings at startup
- [Load .env files](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): load variables from a `.env` file
- [Required values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/required-values.md): read values the application cannot run without
- [Optional values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/optional-values.md): read values that have defaults
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
