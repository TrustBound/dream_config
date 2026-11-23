//// Configuration loading from environment variables and .env files
////
//// This module reads settings from environment variables, and loads `.env`
//// files into the environment. It handles required and optional values,
//// integers and booleans, and gives a typed error for each problem.
////
//// ## Quick Start
////
//// ### Read the settings into a record <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_quick_start.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
////
//// ```gleam
//// import dream_config/loader.{type ConfigError} as config
//// import gleam/result
////
//// pub type Settings {
////   Settings(database_url: String, port: Int, debug_mode: Bool, api_key: String)
//// }
////
//// pub fn load_settings() -> Result(Settings, ConfigError) {
////   // Required: the error names the variable that is not set, empty or wrong
////   use database_url <- result.try(config.get_required("DATABASE_URL"))
////   use port <- result.try(config.get_required_int("PORT"))
////
////   // Optional, with defaults
////   let debug_mode = config.get_bool("DEBUG")
////   let api_key = config.get("API_KEY") |> result.unwrap("default-key")
////
////   Ok(Settings(database_url:, port:, debug_mode:, api_key:))
//// }
//// ```
////
//// ## Loading .env Files
////
//// Call `load_dotenv()` at application startup to load variables from a `.env`
//// file in the current working directory. A variable that is already set in
//// the environment keeps its value, so the values that the platform sets win
//// over the file. A missing `.env` file is not an error. A `.env` file that
//// cannot be read or has a line that is not valid is a `LoadError`.
////
//// `load_dotenv_override()` and `load_dotenv_override_from(path)` let the
//// file win: a value in the file replaces a variable that is already set.
////
//// ## Errors
////
//// The read functions return `Result(_, ConfigError)`. Match on `NotSet`,
//// `NotAnInteger` or `Empty`, or turn the error into text with `describe`.
//// The load functions return `Result(Nil, LoadError)`, and
//// `describe_load_error` gives its text.

import dream_config/internal/dotenv.{type ParseError, type Variable}
import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string

const default_dotenv_path = ".env"

/// Why a setting cannot be read.
///
/// Every read function returns this type, so the reads chain with
/// `result.try`. `describe` gives the text for a log line.
pub type ConfigError {
  /// The environment variable is not set.
  NotSet(name: String)
  /// The variable is set, but its value is not an integer. `value` is the
  /// value as it is in the environment.
  NotAnInteger(name: String, value: String)
  /// A required variable is set to an empty string.
  Empty(name: String)
}

/// Why a `.env` file cannot be loaded.
///
/// `path` is the path of the file. `line` is the line number (from 1) of the
/// line that is not valid. For a quote that is not closed, it is the line of
/// the opening quote. `describe_load_error` gives the text for a log line.
pub type LoadError {
  /// No file is at the path. `load_dotenv()` does not return this error,
  /// because the default `.env` file is optional.
  FileNotFound(path: String)
  /// The file is there but cannot be read, for example because of its
  /// permissions or because it is a directory. `reason` is the reason from
  /// the operating system, for example `permission denied`.
  FileNotReadable(path: String, reason: String)
  /// The file is not valid UTF-8 text.
  FileNotUtf8(path: String)
  /// A line has no `=` after the name.
  MissingEquals(path: String, line: Int)
  /// The name before the `=` is empty.
  EmptyName(path: String, line: Int)
  /// A quoted value has no closing quote.
  QuoteNotClosed(path: String, line: Int, quote: Quote)
  /// Text other than spaces or a `#` comment follows a closing quote.
  TextAfterClosingQuote(path: String, line: Int, quote: Quote)
}

/// The kind of quote around a value in a `.env` file.
pub type Quote {
  /// `"`
  DoubleQuote
  /// `'`
  SingleQuote
  /// `` ` ``
  Backtick
}

/// Why a file could not be read as text. The Erlang FFI returns it.
type ReadError {
  ReadMissing
  ReadNotUtf8
  ReadFailed(reason: String)
}

/// Which value a load keeps when a variable of the file is already set.
type Precedence {
  EnvironmentWins
  FileWins
}

@external(erlang, "dream_config_ffi", "read_text_file")
fn read_text_file(path: String) -> Result(String, ReadError)

/// Load `.env` file from the default location
///
/// Reads the `.env` file in the current working directory and sets each
/// variable of the file that is not set yet in the environment. A variable
/// that is already set keeps its value, also when its value is an empty
/// string. This is typically called at application startup.
///
/// The file format is `NAME=VALUE`, one variable on each line. Lines that
/// start with `#` are comments. Values can be in double quotes, single quotes
/// or backticks. Names are changed to upper case. When a name is on more than
/// one line, the last line wins. A byte order mark at the start of the file is
/// skipped.
///
/// The file is optional, so that the same code runs where the environment
/// variables are set directly (for example in production).
///
/// ## Returns
///
/// - `Ok(Nil)`: The file does not exist (nothing is set), or the file exists
///   and each of its variables that was not set is now set
/// - `Error(LoadError)`: The file exists but cannot be read (for example no
///   permission, a directory, or not UTF-8), or a line is not valid. On an
///   error, no variable from the file is set.
///
/// ## See Also
///
/// - `load_dotenv_override`: let the values in the file win
/// - `load_dotenv_from`: load a `.env` file from another path
///
/// ## Example
///
/// ### Load the .env file at startup <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
/// import gleam/result
///
/// pub fn database_url_at_startup() -> Result(String, String) {
///   // A missing .env file is not an error, a malformed one is
///   use _ <- result.try(
///     config.load_dotenv() |> result.map_error(config.describe_load_error),
///   )
///   config.get_required("DATABASE_URL") |> result.map_error(config.describe)
/// }
/// ```
pub fn load_dotenv() -> Result(Nil, LoadError) {
  load_default_file(EnvironmentWins)
}

/// Load `.env` file from the default location, and let the file win
///
/// The same as `load_dotenv`, but each variable of the file is set, also
/// when it is already set in the environment. A value in the file replaces
/// the value that is set. A missing `.env` file is not an error.
///
/// Use it when the file must win, for example when a value that your shell
/// exported for another project must not hide the value in this project's
/// `.env` file.
///
/// ## Returns
///
/// - `Ok(Nil)`: The file does not exist (nothing is set), or the file exists
///   and all its variables are set
/// - `Error(LoadError)`: The file exists but cannot be read, or a line is not
///   valid. On an error, no variable from the file is set.
///
/// ## Example
///
/// ### Let the .env file win <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_override.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
/// import gleam/result
///
/// pub fn database_url_from_file() -> Result(String, String) {
///   // The value in the .env file replaces a variable that is already set
///   use _ <- result.try(
///     config.load_dotenv_override()
///     |> result.map_error(config.describe_load_error),
///   )
///   config.get_required("DATABASE_URL") |> result.map_error(config.describe)
/// }
/// ```
pub fn load_dotenv_override() -> Result(Nil, LoadError) {
  load_default_file(FileWins)
}

/// Load `.env` file from a specific path
///
/// Reads the `.env` file at the specified path and sets each variable of the
/// file that is not set yet in the environment, in the same format as
/// `load_dotenv`. A variable that is already set keeps its value. Useful when
/// your `.env` file is in a non-standard location.
///
/// ## Parameters
///
/// - `path`: The file path to the `.env` file
///
/// ## Returns
///
/// - `Ok(Nil)`: The file was read, and each of its variables that was not set
///   is now set
/// - `Error(LoadError)`: The file does not exist, cannot be read, or has a
///   line that is not valid. On an error, no variable from the file is set.
///
/// ## Example
///
/// ### Load a .env file from a path <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_from.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader.{type LoadError} as config
///
/// pub fn load_settings_file(path: String) -> Result(Nil, LoadError) {
///   // For example "/etc/myapp/.env". A missing file is an error.
///   config.load_dotenv_from(path)
/// }
/// ```
pub fn load_dotenv_from(path: String) -> Result(Nil, LoadError) {
  load_file(path, EnvironmentWins)
}

/// Load `.env` file from a specific path, and let the file win
///
/// The same as `load_dotenv_from`, but each variable of the file is set, also
/// when it is already set in the environment. A value in the file replaces
/// the value that is set.
///
/// ## Parameters
///
/// - `path`: The file path to the `.env` file
///
/// ## Returns
///
/// - `Ok(Nil)`: The file was read and all its variables are set
/// - `Error(LoadError)`: The file does not exist, cannot be read, or has a
///   line that is not valid. On an error, no variable from the file is set.
///
/// ## Example
///
/// ### Let a file from a path win <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_override_from.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader.{type LoadError} as config
///
/// pub fn load_profile(path: String) -> Result(Nil, LoadError) {
///   // For example "config/staging.env". Its values replace the ones that are set.
///   config.load_dotenv_override_from(path)
/// }
/// ```
pub fn load_dotenv_override_from(path: String) -> Result(Nil, LoadError) {
  load_file(path, FileWins)
}

fn load_default_file(precedence: Precedence) -> Result(Nil, LoadError) {
  case read_text_file(default_dotenv_path) {
    Ok(text) -> set_variables_from_text(default_dotenv_path, text, precedence)
    Error(ReadMissing) -> Ok(Nil)
    Error(error) ->
      Error(load_error_from_read_error(default_dotenv_path, error))
  }
}

fn load_file(path: String, precedence: Precedence) -> Result(Nil, LoadError) {
  use text <- result.try(
    read_text_file(path)
    |> result.map_error(load_error_from_read_error(path, _)),
  )
  set_variables_from_text(path, text, precedence)
}

/// Decides which variables to set from the environment as it is before the
/// load, so that a name on two lines of the file gets the value of the last
/// line with both precedences.
fn set_variables_from_text(
  path: String,
  text: String,
  precedence: Precedence,
) -> Result(Nil, LoadError) {
  use variables <- result.try(
    dotenv.parse(text)
    |> result.map_error(load_error_from_parse_error(path, _)),
  )
  variables
  |> list.filter(should_set(_, precedence))
  |> list.each(set_variable)
  Ok(Nil)
}

fn should_set(variable: Variable, precedence: Precedence) -> Bool {
  case precedence {
    FileWins -> True
    EnvironmentWins -> !is_set(variable.name)
  }
}

fn set_variable(variable: Variable) -> Nil {
  envoy.set(variable.name, variable.value)
}

fn load_error_from_read_error(path: String, error: ReadError) -> LoadError {
  case error {
    ReadMissing -> FileNotFound(path)
    ReadNotUtf8 -> FileNotUtf8(path)
    ReadFailed(reason) -> FileNotReadable(path, reason)
  }
}

fn load_error_from_parse_error(path: String, error: ParseError) -> LoadError {
  case error {
    dotenv.MissingEquals(line) -> MissingEquals(path, line)
    dotenv.EmptyName(line) -> EmptyName(path, line)
    dotenv.QuoteNotClosed(line, quote) ->
      QuoteNotClosed(path, line, quote_from_parser(quote))
    dotenv.TextAfterClosingQuote(line, quote) ->
      TextAfterClosingQuote(path, line, quote_from_parser(quote))
  }
}

fn quote_from_parser(quote: dotenv.Quote) -> Quote {
  case quote {
    dotenv.DoubleQuote -> DoubleQuote
    dotenv.SingleQuote -> SingleQuote
    dotenv.Backtick -> Backtick
  }
}

/// Describe a `LoadError` in one line
///
/// Gives the text for a log line or for the message when the app stops. The
/// text starts with `Cannot load .env file at` and the path, then gives the
/// reason, and the line number for a line that is not valid.
///
/// | Error | Text |
/// |:---|:---|
/// | `FileNotFound(".env")` | `Cannot load .env file at .env: the file does not exist` |
/// | `FileNotReadable(".env", "permission denied")` | `Cannot load .env file at .env: permission denied` |
/// | `FileNotUtf8(".env")` | `Cannot load .env file at .env: the file is not valid UTF-8` |
/// | `MissingEquals(".env", 2)` | `Cannot load .env file at .env: line 2: expected NAME=VALUE` |
/// | `EmptyName(".env", 2)` | `Cannot load .env file at .env: line 2: expected NAME=VALUE` |
/// | `QuoteNotClosed(".env", 1, DoubleQuote)` | `Cannot load .env file at .env: line 1: the double quote is not closed` |
/// | `TextAfterClosingQuote(".env", 1, SingleQuote)` | `Cannot load .env file at .env: line 1: unexpected text after the closing single quote` |
///
/// ## Example
///
/// ### Load a file or explain why not <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_describe_load_error.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
/// import gleam/result
///
/// pub fn load_or_explain(path: String) -> Result(Nil, String) {
///   config.load_dotenv_from(path)
///   |> result.map_error(config.describe_load_error)
/// }
/// ```
pub fn describe_load_error(error: LoadError) -> String {
  "Cannot load .env file at " <> error.path <> ": " <> load_error_reason(error)
}

fn load_error_reason(error: LoadError) -> String {
  case error {
    FileNotFound(_) -> "the file does not exist"
    FileNotReadable(_, reason) -> reason
    FileNotUtf8(_) -> "the file is not valid UTF-8"
    MissingEquals(_, line) | EmptyName(_, line) ->
      line_reason(line, "expected NAME=VALUE")
    QuoteNotClosed(_, line, quote) ->
      line_reason(line, "the " <> quote_name(quote) <> " is not closed")
    TextAfterClosingQuote(_, line, quote) ->
      line_reason(
        line,
        "unexpected text after the closing " <> quote_name(quote),
      )
  }
}

fn line_reason(line: Int, reason: String) -> String {
  "line " <> int.to_string(line) <> ": " <> reason
}

fn quote_name(quote: Quote) -> String {
  case quote {
    DoubleQuote -> "double quote"
    SingleQuote -> "single quote"
    Backtick -> "backtick"
  }
}

/// Returns the value of a variable, or `NotSet`. This is the only place that
/// decides whether a variable is set: a variable with an empty value is set.
fn lookup(name: String) -> Result(String, ConfigError) {
  envoy.get(name) |> result.replace_error(NotSet(name))
}

fn is_set(name: String) -> Bool {
  result.is_ok(lookup(name))
}

fn parse_int(name: String, value: String) -> Result(Int, ConfigError) {
  int.parse(value) |> result.replace_error(NotAnInteger(name, value))
}

/// Get a required environment variable
///
/// Returns the value of the environment variable if it is set and not empty.
/// Use this for configuration values that your application cannot run
/// without.
///
/// ## Parameters
///
/// - `name`: The name of the environment variable
///
/// ## Returns
///
/// - `Ok(String)`: The variable value
/// - `Error(NotSet(name))`: The variable is not set
/// - `Error(Empty(name))`: The variable is set to an empty string. Use `get`
///   for a value that can be empty.
///
/// ## Example
///
/// ### Read a required value <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_get_required.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
///
/// pub fn database_url() -> Result(String, String) {
///   case config.get_required("DATABASE_URL") {
///     Ok(url) -> Ok(url)
///     Error(error) ->
///       Error("Cannot start the application: " <> config.describe(error))
///   }
/// }
/// ```
pub fn get_required(name: String) -> Result(String, ConfigError) {
  use value <- result.try(lookup(name))
  case value {
    "" -> Error(Empty(name))
    _ -> Ok(value)
  }
}

/// Get an optional environment variable
///
/// Returns the value if the variable is set, or `Error(NotSet(name))` if it is
/// not. An empty value is a value: `get` returns `Ok("")` for it. Use this
/// for configuration values that have sensible defaults or are truly
/// optional.
///
/// ## Parameters
///
/// - `name`: The name of the environment variable
///
/// ## Returns
///
/// - `Ok(String)`: The variable value, which can be empty
/// - `Error(NotSet(name))`: The variable is not set
///
/// ## Example
///
/// ### Read an optional value <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_get.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
/// import gleam/option.{type Option}
///
/// pub fn api_key() -> Option(String) {
///   case config.get("API_KEY") {
///     Ok(key) -> option.Some(key)
///     Error(_) -> option.None
///   }
/// }
/// ```
pub fn get(name: String) -> Result(String, ConfigError) {
  lookup(name)
}

/// Get an environment variable as an integer
///
/// Parses the environment variable as an integer, with `int.parse`. The two
/// errors are different, so you can give a default only when the variable is
/// not set, and stop on a value that is wrong.
///
/// ## Parameters
///
/// - `name`: The name of the environment variable
///
/// ## Returns
///
/// - `Ok(Int)`: The parsed integer value
/// - `Error(NotSet(name))`: The variable is not set
/// - `Error(NotAnInteger(name, value))`: The value is not an integer. An
///   empty value is not an integer either.
///
/// ## Example
///
/// ### Use a default only when the setting is not set <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_typed_values_port.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader.{type ConfigError, NotSet} as config
///
/// pub fn port() -> Result(Int, ConfigError) {
///   case config.get_int("PORT") {
///     Error(NotSet(_)) -> Ok(3000)
///     other -> other
///   }
/// }
/// ```
pub fn get_int(name: String) -> Result(Int, ConfigError) {
  use value <- result.try(lookup(name))
  parse_int(name, value)
}

/// Get a required environment variable as an integer
///
/// Returns the parsed integer value if the variable is set and valid. Use
/// this for required numeric configuration like port numbers or timeouts.
///
/// ## Parameters
///
/// - `name`: The name of the environment variable
///
/// ## Returns
///
/// - `Ok(Int)`: The parsed integer value
/// - `Error(NotSet(name))`: The variable is not set
/// - `Error(Empty(name))`: The variable is set to an empty string
/// - `Error(NotAnInteger(name, value))`: The value is not an integer
///
/// ## Example
///
/// ### Read a required integer <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_get_required_int.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader.{type ConfigError} as config
/// import gleam/int
/// import gleam/result
///
/// pub fn listen_address() -> Result(String, ConfigError) {
///   use port <- result.try(config.get_required_int("PORT"))
///   Ok("0.0.0.0:" <> int.to_string(port))
/// }
/// ```
pub fn get_required_int(name: String) -> Result(Int, ConfigError) {
  use value <- result.try(get_required(name))
  parse_int(name, value)
}

/// Describe a `ConfigError` in one line
///
/// Gives the text for a log line or for the message when the app stops. The
/// text names the variable.
///
/// | Error | Text |
/// |:---|:---|
/// | `NotSet("PORT")` | `Required environment variable not set: PORT` |
/// | `NotAnInteger("PORT", "eighty")` | `Environment variable PORT must be an integer` |
/// | `Empty("DATABASE_URL")` | `Required environment variable is empty: DATABASE_URL` |
///
/// ## Example
///
/// ### Describe a problem with PORT <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_describe.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
///
/// pub fn port_problem() -> String {
///   case config.get_required_int("PORT") {
///     Ok(_) -> "PORT is valid"
///     Error(error) -> config.describe(error)
///   }
/// }
/// ```
pub fn describe(error: ConfigError) -> String {
  case error {
    NotSet(name) -> "Required environment variable not set: " <> name
    NotAnInteger(name, _) ->
      "Environment variable " <> name <> " must be an integer"
    Empty(name) -> "Required environment variable is empty: " <> name
  }
}

/// Get an environment variable as a boolean
///
/// Parses the environment variable as a boolean. The following values are
/// treated as `True`, in any mix of upper and lower case (for example `tRUE`
/// or `Yes`):
/// - `"true"`
/// - `"1"`
/// - `"yes"`
///
/// All other values (including unset variables, and values with spaces around
/// them) are treated as `False`.
///
/// ## Parameters
///
/// - `name`: The name of the environment variable
///
/// ## Returns
///
/// - `True`: Variable is set to a truthy value
/// - `False`: Variable is not set or set to a falsy value
///
/// ## Example
///
/// ### Pick a log level from DEBUG <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_boolean_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_config/loader as config
///
/// pub fn log_level() -> String {
///   let debug_mode = config.get_bool("DEBUG")
///   case debug_mode {
///     True -> "debug"
///     False -> "info"
///   }
/// }
/// ```
pub fn get_bool(name: String) -> Bool {
  case lookup(name) {
    Ok(value) -> is_true_value(string.lowercase(value))
    Error(_) -> False
  }
}

fn is_true_value(lowercase_value: String) -> Bool {
  case lowercase_value {
    "true" | "1" | "yes" -> True
    _ -> False
  }
}
