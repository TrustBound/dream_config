# Load .env files

This guide shows how to load variables from a `.env` file into the environment. After you load the file, you read the values with the `get*` functions.

## Load the default file and a file at a path

`load_dotenv()` reads `.env` in the current directory. A missing `.env` file is not an error, so the same code runs where the variables are set directly. `load_dotenv_from(path)` reads the file at `path`, and a missing file is an error. Use it when your `.env` file is in a non-standard location.

Each variable in the file is set in the environment. A variable that is already set gets the value from the file.

### Load two files <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/readme_load_env_files.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## When to load a .env file

Call `load_dotenv()` at application startup. This is useful for local development. For production, set environment variables directly (for example with systemd or Docker) and skip `.env` loading.

## The file format

- The format is `NAME=VALUE`, one variable on each line.
- Lines that start with `#` are comments.
- Values can be in double quotes, single quotes or backticks.
- Names are changed to upper case.

## Errors

Both functions return `Error(String)` with the path and the reason when the file cannot be read (for example no permission, a directory, or not UTF-8), or when a line is not valid. On an error, no variable from the file is set. Some examples of the message:

- The file cannot be read: `Cannot load .env file at .env: permission denied`
- A line is not valid (no `=`, an empty name, a quote that is not closed, or text after a closing quote). The message gives the line number: `Cannot load .env file at .env: line 2: expected NAME=VALUE`
- `load_dotenv_from(path)` only, the file does not exist: `Cannot load .env file at /etc/myapp/.env: the file does not exist`

## Functions

- `load_dotenv() -> Result(Nil, String)`: load from the default location (a missing file is `Ok(Nil)`)
- `load_dotenv_from(path: String) -> Result(Nil, String)`: load from a specific path (a missing file is an error)

## See also

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): install the package and load settings at startup
- [Required values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/required-values.md): read values the application cannot run without
- [Optional values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/optional-values.md): read values that have defaults
- [Boolean values](https://github.com/TrustBound/dream_config/blob/main/docs/guides/boolean-values.md): read a variable as `True` or `False`
- [README](https://github.com/TrustBound/dream_config/blob/main/README.md)
