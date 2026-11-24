# Load your app's settings at startup

Your app needs a few things from outside its code: a database URL, a port, an API key, a switch for debug logs. You set them as environment variables, so the same build runs on your laptop, in CI and in production. But an environment variable is only a string, and it can be missing or empty. You want to read all of them one time when the app starts, turn them into a typed record, and stop at once with a clear message when one of them is missing or wrong. This guide walks you through that, from the first value to a tested `main`.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Read the required settings](#step-1-read-the-required-settings)
- [Step 2: Add settings with defaults](#step-2-add-settings-with-defaults)
- [Step 3: Load the .env file and the settings once in main](#step-3-load-the-env-file-and-the-settings-once-in-main)
- [When a setting is missing or wrong](#when-a-setting-is-missing-or-wrong)
- [Which function to use](#which-function-to-use)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Read the settings that your app cannot run without, and get an error that names a missing, empty or wrong one.
- Add settings that have defaults.
- Load a `.env` file and the settings one time in `main`, and stop with a message and exit status 1 when a setting is missing or wrong.
- Test the code that reads your settings.

## Before you start

Add the package to your project:

```sh
gleam add dream_config
```

dream_config has no dependency on Dream or on any framework, so you can use it in any Gleam project that runs on Erlang.

All the functions are in one module, `dream_config/loader`. The examples import it as `config`.

To run an example, set the variables in the shell where you start it. In your project, that is `DATABASE_URL=postgres://localhost/app PORT=8080 gleam run`. In a clone of this repository, this command runs the program of [Step 3](#step-3-load-the-env-file-and-the-settings-once-in-main), and CI runs it too:

### Run the program of Step 3 <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/scripts/check.sh#L12"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```sh
DATABASE_URL=postgres://localhost/app PORT=8080 gleam run -m snippets/guide_getting_started_main
```

## Step 1: Read the required settings

Start with the settings that your app cannot run without. Describe them as a type, and read each one with a `get_required` function:

### Load required settings <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_required_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{type ConfigError} as config
import gleam/result

pub type AppConfig {
  AppConfig(database_url: String, port: Int)
}

pub fn load_config() -> Result(AppConfig, ConfigError) {
  use database_url <- result.try(config.get_required("DATABASE_URL"))
  use port <- result.try(config.get_required_int("PORT"))

  Ok(AppConfig(database_url: database_url, port: port))
}
```

`get_required("DATABASE_URL")` returns `Ok` with the value of the variable. When the variable is not set, it returns `Error(NotSet("DATABASE_URL"))`. When the variable is set to an empty string, it returns `Error(Empty("DATABASE_URL"))`, because an empty database URL is as bad as none. `get_required_int("PORT")` does the same, and it also parses the value as an integer.

All the read functions return the same error type, `ConfigError`, so they chain with `result.try`. The first setting that fails stops the chain and becomes the result.

With `DATABASE_URL=postgres://localhost/app` and `PORT=8080`, `load_config()` returns:

### The settings that load <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_1_loaded.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok(AppConfig("postgres://localhost/app", 8080))
```

When `DATABASE_URL` is not set, it returns:

### A required setting that is not set <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_1_not_set.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Error(NotSet("DATABASE_URL"))
```

When `DATABASE_URL` is set to an empty string, for example by a `DATABASE_URL=` line, it returns:

### A required setting that is empty <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_1_empty.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Error(Empty("DATABASE_URL"))
```

When `PORT` is `eighty`, it returns the name and the value:

### A port that is not an integer <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_1_not_an_integer.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Error(NotAnInteger("PORT", "eighty"))
```

The rest of your app gets an `AppConfig`, not strings from the environment. A function that needs the port takes an `Int`, and it never has to ask whether the port is set.

## Step 2: Add settings with defaults

Most apps also have settings with a sensible default. This is the complete settings loader:

### Read the settings into a record <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_quick_start.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{type ConfigError} as config
import gleam/result

pub type Settings {
  Settings(database_url: String, port: Int, debug_mode: Bool, api_key: String)
}

pub fn load_settings() -> Result(Settings, ConfigError) {
  // Required: the error names the variable that is not set, empty or wrong
  use database_url <- result.try(config.get_required("DATABASE_URL"))
  use port <- result.try(config.get_required_int("PORT"))

  // Optional, with defaults
  let debug_mode = config.get_bool("DEBUG")
  let api_key = config.get("API_KEY") |> result.unwrap("default-key")

  Ok(Settings(database_url:, port:, debug_mode:, api_key:))
}
```

Two new functions read the optional settings:

- `config.get_bool("DEBUG")` is `True` for `true`, `1` or `yes` in any letter case, and `False` for anything else, including a variable that is not set.
- `config.get("API_KEY")` returns `Error(NotSet("API_KEY"))` when the variable is not set, and `result.unwrap` turns that into the default. For a string, "not set" is the only error, so `result.unwrap` is safe here. For a number, it is not: the [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md) shows the read that keeps a typo from becoming the default.

With `DATABASE_URL=postgres://localhost/app`, `PORT=8080`, `DEBUG=true` and no `API_KEY`, `load_settings()` returns:

### The settings with defaults <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_2_loaded.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok(Settings("postgres://localhost/app", 8080, True, "default-key"))
```

When `PORT` is not set, it returns:

### A port that is not set <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_2_port_not_set.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Error(NotSet("PORT"))
```

## Step 3: Load the .env file and the settings once in main

Now call the loader from `main`. First load the `.env` file that holds the values for local development. Then load the settings. When they load, start the app with them. When they do not, print the reason to standard error and stop with exit status 1, so that a shell script, a container platform or a process supervisor sees the failure:

### Start the app or stop with the reason <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_getting_started_main.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/int
import gleam/io
import gleam/result
import snippets/readme_quick_start.{type Settings, load_settings}

pub fn main() -> Nil {
  case start() {
    Ok(message) -> io.println(message)
    Error(reason) -> {
      io.println_error("Cannot start: " <> reason)
      halt(1)
    }
  }
}

pub fn start() -> Result(String, String) {
  // Local values. A variable that is already set keeps its value.
  use _ <- result.try(
    config.load_dotenv() |> result.map_error(config.describe_load_error),
  )
  use settings <- result.try(
    load_settings() |> result.map_error(config.describe),
  )
  Ok(serve(settings))
}

fn serve(settings: Settings) -> String {
  "Listening on port " <> int.to_string(settings.port)
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
```

`snippets/readme_quick_start` is the module from Step 2. In your app, it is your own settings module, for example `app/settings`.

Here is what each part does:

- `config.load_dotenv()` reads the file `.env` in the current directory, and sets each variable of the file that is not set yet. A variable that the shell or the platform sets keeps its value. When there is no `.env` file, it returns `Ok(Nil)` and sets nothing. That is what you want in production, where the platform sets the variables and there is no file. A `.env` file that is there but is not valid is an error. The [.env guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md) covers the file.
- `config.describe_load_error` and `config.describe` turn the two error types into one line of text. `start()` returns a `Result(String, String)`, so you can test it without stopping anything.
- In a real app, `serve` starts your web server or your supervision tree. Here it returns a message, so you can see that the port arrived as an `Int`.
- `main()` is the only place that decides what a failure means for the whole program. It prints `Cannot start: ` and the reason with `io.println_error`.
- `halt(1)` is Erlang's `erlang:halt/1`. It stops the BEAM with that exit status. The snippet declares it with `@external`, so it needs no other package.

With `DATABASE_URL=postgres://localhost/app` and `PORT=8080`, the program prints this and exits with status 0:

### The program starts <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_3_environment.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Listening on port 8080
```

With no variables set and a `.env` file that holds `DATABASE_URL=postgres://localhost/app` and `PORT=4000`, it prints:

### The program starts with the .env file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_3_env_file.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Listening on port 4000
```

With the same file and `PORT=8080` set in the shell, the shell wins, and it prints:

### The shell wins over the .env file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_step_3_shell_wins.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Listening on port 8080
```

## When a setting is missing or wrong

Each failure stops the program before it does any work, with one line that names the variable. When `DATABASE_URL` is not set, the program prints this and exits with status 1:

### The program stops on a missing setting <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_missing_setting.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Cannot start: Required environment variable not set: DATABASE_URL
```

When `DATABASE_URL` is set to an empty string, it prints this and exits with status 1:

### The program stops on an empty setting <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_empty_setting.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Cannot start: Required environment variable is empty: DATABASE_URL
```

When `PORT` is set to `eighty`, it prints this and exits with status 1:

### The program stops on a wrong setting <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_wrong_setting.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Cannot start: Environment variable PORT must be an integer
```

When the `.env` file has a line that is not valid, for example `DATABASE_URL` with no `=`, it prints the path and the line number, and exits with status 1:

### The program stops on a bad .env line <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_getting_started_bad_env_line.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Cannot start: Cannot load .env file at .env: line 1: expected NAME=VALUE
```

The [.env guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md#when-the-file-is-bad) lists each error for a bad file.

Two things do not stop the program, because you tell the functions that a problem is not one:

- An optional number that you read with `result.unwrap(default)`. `get_int("PORT")` returns `Error(NotAnInteger("PORT", "eighty"))` for a typo, but `result.unwrap` throws that error away. Match on `NotSet` instead, as the [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md#step-1-give-an-optional-number-a-default) shows.
- A switch with a value that `get_bool` does not know, such as `on`. It is `False`, with no error.

## Which function to use

| Your setting | Use | Why |
|:---|:---|:---|
| A string the app cannot run without, such as a database URL | `get_required(name)` | Its error is `NotSet` or `Empty`, with the name. |
| A number the app cannot run without | `get_required_int(name)` | It also rejects a value that is not an integer, with `NotAnInteger(name, value)`. |
| A string with a default, or one that can be absent or empty | `get(name)` | `NotSet` is its only error. Pick the default with `result.unwrap`, or keep an `Option`. |
| A number with a default | `get_int(name)`, and a default only for `NotSet` | A typo stops the app. See the [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md#step-1-give-an-optional-number-a-default). |
| An on or off switch | `get_bool(name)` | `true`, `1` and `yes` in any letter case are `True`. Everything else is `False`. |
| Local values in a file | `load_dotenv()` | It reads `.env` in the current directory. No file is not an error. A variable that is set wins over the file. |
| A file at a known path, such as a secrets file | `load_dotenv_from(path)` | A missing file is an error. |
| The text of an error | `describe(error)` or `describe_load_error(error)` | One line that names the variable or the file. |

## Test your code

Your settings loader reads the environment of the BEAM it runs in. A test sets the variables, calls the loader, and unsets the variables after. Here is a test module for `load_settings` from Step 2. It uses [dream_test](https://hexdocs.pm/dream_test):

### Test load_settings <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_getting_started_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{NotSet}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/readme_quick_start.{Settings, load_settings}

pub fn tests() -> TestSuite {
  describe("load_settings", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      Ok(Nil)
    }),
    it("reads every setting from the environment", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/test")
      envoy.set("PORT", "4000")
      envoy.set("DEBUG", "yes")
      envoy.set("API_KEY", "test-key")

      // Act
      let settings = load_settings()

      // Assert
      settings
      |> should
      |> be_equal(
        Ok(Settings(
          database_url: "postgres://localhost/test",
          port: 4000,
          debug_mode: True,
          api_key: "test-key",
        )),
      )
      |> or_fail_with("Expected the settings from the environment")
    }),
    it("names the setting that is missing", fn() {
      // Arrange
      envoy.set("PORT", "4000")

      // Act
      let settings = load_settings()

      // Assert
      settings
      |> should
      |> be_equal(Error(NotSet("DATABASE_URL")))
      |> or_fail_with("Expected an error that names DATABASE_URL")
    }),
  ])
}
```

The `after_each` hook unsets every variable that a test can set, so the next test starts from a clean environment. Unset is also how you test a missing value: the second test sets only `PORT`, and expects `NotSet("DATABASE_URL")`. The test compares the error value, not its text, so a change in the wording of a message cannot break it.

Environment variables belong to the whole BEAM, not to one test process. Two tests that run at the same time and set the same variable see each other's values. Run the tests that touch the environment one at a time. With dream_test, that is `runner.max_concurrency(1)` on the runner, as [this package's own test runner](https://github.com/TrustBound/dream_config/blob/main/test/dream_config_test.gleam) does.

`start()` from Step 3 returns a `Result`, so you test it in the same way. Keep `main()` small, because a test cannot call it: `halt` would stop the test run.

## Common pitfalls

**Reading the environment all over the code.** *Symptom:* a missing variable shows up as a crash in the middle of a request, hours after a deploy. *Fix:* read every setting one time in `main`, as in [Step 3](#step-3-load-the-env-file-and-the-settings-once-in-main), and pass the record to the code that needs it.

**Tests that change the same variables at the same time.** *Symptom:* a settings test fails now and then, with a value that another test set. *Fix:* run those tests one at a time, with `runner.max_concurrency(1)`.

**A `.env` file in the project changes your tests.** *Symptom:* a test expects `NotSet("DATABASE_URL")`, but gets the value from your local `.env` file. *Fix:* `load_dotenv()` sets each variable of the file that the test did not set. Call `config.load_dotenv()` in `start`, before `load_settings()`, not inside `load_settings`, as in Step 3. Then the tests of `load_settings` never read the file.

**Matching on the text of an error.** *Symptom:* a check such as `string.contains(message, "not set")` breaks when a message changes. *Fix:* match on the error value, `NotSet(name)`, `Empty(name)` or `NotAnInteger(name, value)`. Use `describe` only for the text that a person reads.

**The app starts from another directory.** *Symptom:* the app works with `gleam run` in the project, but reports a missing variable when you start it from somewhere else. *Fix:* `load_dotenv()` reads `.env` in the current working directory, and returns `Ok(Nil)` when it is not there. Start the app from the directory that holds the file, or load the file by its full path with `load_dotenv_from(path)`.

## Where to go next

- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): which value wins, the file format, a second file for secrets, and the errors for a bad file.
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md): defaults that do not hide a typo, ranges, and the values that `get_bool` accepts.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): every function and error type of `dream_config/loader`.
