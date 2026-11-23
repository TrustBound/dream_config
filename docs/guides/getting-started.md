# Load your app's settings at startup

Your app needs a few things from outside its code: a database URL, a port, an API key, a switch for debug logs. You set them as environment variables, so the same build runs on your laptop, in CI and in production. But an environment variable is only a string, and it can be missing. You want to read all of them one time when the app starts, turn them into a typed record, and stop at once with a clear message when one of them is missing or wrong. This guide walks you through that, from the first value to a tested `main`.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Read the required settings](#step-1-read-the-required-settings)
- [Step 2: Add defaults and a .env file](#step-2-add-defaults-and-a-env-file)
- [Step 3: Load the settings once in main](#step-3-load-the-settings-once-in-main)
- [When a setting is missing or wrong](#when-a-setting-is-missing-or-wrong)
- [Which function to use](#which-function-to-use)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Read the settings that your app cannot run without, and get an error that names a missing one.
- Add settings that have defaults, and load a `.env` file for local development.
- Load the settings one time in `main`, and stop with a message and exit status 1 when a setting is missing or wrong.
- Test the code that reads your settings.

## Before you start

Add the package to your project:

```sh
gleam add dream_config
```

dream_config has no dependency on Dream or on any framework, so you can use it in any Gleam project that runs on Erlang.

All the functions are in one module, `dream_config/loader`. The examples import it as `config`.

To run an example, set the variables in the shell where you start it, for example:

```sh
DATABASE_URL=postgres://localhost/app PORT=8080 gleam run
```

## Step 1: Read the required settings

Start with the settings that your app cannot run without. Describe them as a type, and read each one with a `get_required` function:

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

`get_required("DATABASE_URL")` returns `Ok` with the value of the variable, or an `Error(String)` that names the variable when it is not set. `get_required_int("PORT")` does the same, and it also parses the value as an integer. Both errors are strings, so they chain with `result.try`. The first setting that fails stops the chain and becomes the result.

With `DATABASE_URL=postgres://localhost/app` and `PORT=8080`, `load_config()` returns:

```text
Ok(AppConfig(database_url: "postgres://localhost/app", port: 8080))
```

When `DATABASE_URL` is not set, it returns:

```text
Error("Required environment variable not set: DATABASE_URL")
```

When `PORT` is `eighty`, it returns:

```text
Error("Environment variable PORT must be an integer")
```

The rest of your app gets an `AppConfig`, not strings from the environment. A function that needs the port takes an `Int`, and it never has to ask whether the port is set.

## Step 2: Add defaults and a .env file

Most apps also have settings with a sensible default, and a developer wants to keep the local values in a file instead of typing them for each run. This is the complete loader:

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

Two new things happen here:

- `config.load_dotenv()` reads the file `.env` in the current directory and sets each variable in it. When there is no `.env` file, it returns `Ok(Nil)` and sets nothing. That is what you want in production, where the platform sets the variables and there is no file. A `.env` file that is there but is not valid is an error, and the loader stops on it. The [.env guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md) covers the file.
- `config.get_bool("DEBUG")` is `True` for `true`, `1` or `yes` in any letter case, and `False` for anything else, including a variable that is not set. `config.get("API_KEY")` returns `Error(Nil)` when the variable is not set, and `result.unwrap` turns that into the default. The [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md) covers these functions and their traps.

With `DATABASE_URL=postgres://localhost/app`, `PORT=8080`, `DEBUG=true` and no `API_KEY`, `load_settings()` returns:

```text
Ok(Settings(database_url: "postgres://localhost/app", port: 8080, debug_mode: True, api_key: "default-key"))
```

When `PORT` is not set, it returns:

```text
Error("Required environment variable not set: PORT")
```

## Step 3: Load the settings once in main

Now call the loader from `main`. When the settings load, start the app with them. When they do not, print the reason to standard error and stop with exit status 1, so that a shell script, a container platform or a process supervisor sees the failure:

### Start the app or stop with the reason <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_getting_started_main.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
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
  use settings <- result.try(load_settings())
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

- `start()` loads the settings and hands them to `serve`. It returns a `Result`, so you can test it without stopping anything. In a real app, `serve` starts your web server or your supervision tree. Here it returns a message, so you can see that the port arrived as an `Int`.
- `main()` is the only place that decides what a failure means for the whole program. It prints `Cannot start: ` and the reason with `io.println_error`.
- `halt(1)` is Erlang's `erlang:halt/1`. It stops the BEAM with that exit status. The snippet declares it with `@external`, so it needs no other package.

With `DATABASE_URL=postgres://localhost/app` and `PORT=8080`, the program prints this and exits with status 0:

```text
Listening on port 8080
```

## When a setting is missing or wrong

Each failure stops the program before it does any work, with one line that names the variable. When `DATABASE_URL` is not set, the program prints this and exits with status 1:

```text
Cannot start: Required environment variable not set: DATABASE_URL
```

When `PORT` is set to `eighty`, it prints this and exits with status 1:

```text
Cannot start: Environment variable PORT must be an integer
```

A `.env` file with a line that is not valid also stops the program, with the path and the line number in the message. The [.env guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md#when-the-file-is-bad) lists each of those messages.

Two things do not stop the program, because the functions cannot see a problem:

- An optional setting with a bad value. `get_int("PORT")` returns `Error(Nil)` both when `PORT` is not set and when it is `eighty`, so a default hides the typo. The [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md#step-2-reject-a-bad-number-in-an-optional-setting) shows how to reject it.
- A required setting that is set to an empty string. `get_required` returns `Ok("")` for it.

## Which function to use

| Your setting | Use | Why |
|:---|:---|:---|
| A string the app cannot run without, such as a database URL | `get_required(name)` | Its error names the variable, and it chains with `result.try`. |
| A number the app cannot run without | `get_required_int(name)` | It also rejects a value that is not an integer, with a message that names the variable. |
| A string with a default, or one that can be absent | `get(name)` | `Error(Nil)` means "not set". Pick the default with `result.unwrap`, or keep an `Option`. |
| A number with a default | `get_int(name)` | Only when a typo may fall back to the default. Otherwise use the pattern in the [optional settings guide](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md#step-2-reject-a-bad-number-in-an-optional-setting). |
| An on or off switch | `get_bool(name)` | `true`, `1` and `yes` in any letter case are `True`. Everything else is `False`. |
| Local values in a file | `load_dotenv()` | It reads `.env` in the current directory. No file is not an error. |
| A file at a known path, such as a secrets file | `load_dotenv_from(path)` | A missing file is an error. |

## Test your code

Your settings loader reads the environment of the BEAM it runs in. A test sets the variables, calls the loader, and unsets the variables after. Here is a test module for `load_settings` from Step 2. It uses [dream_test](https://hexdocs.pm/dream_test):

### Test load_settings <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_getting_started_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
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
      |> be_equal(Error("Required environment variable not set: DATABASE_URL"))
      |> or_fail_with("Expected an error that names DATABASE_URL")
    }),
  ])
}
```

The `after_each` hook unsets every variable that a test can set, so the next test starts from a clean environment. Unset is also how you test a missing value: the second test sets only `PORT`, and expects the error that names `DATABASE_URL`.

Environment variables belong to the whole BEAM, not to one test process. Two tests that run at the same time and set the same variable see each other's values. Run the tests that touch the environment one at a time. With dream_test, that is `runner.max_concurrency(1)` on the runner, as [this package's own test runner](https://github.com/TrustBound/dream_config/blob/main/test/dream_config_test.gleam) does.

`start()` from Step 3 returns a `Result`, so you test it in the same way. Keep `main()` small, because a test cannot call it: `halt` would stop the test run.

## Common pitfalls

**Reading the environment all over the code.** *Symptom:* a missing variable shows up as a crash in the middle of a request, hours after a deploy. *Fix:* read every setting one time in `main`, as in [Step 3](#step-3-load-the-settings-once-in-main), and pass the record to the code that needs it.

**Tests that change the same variables at the same time.** *Symptom:* a settings test fails now and then, with a value that another test set. *Fix:* run those tests one at a time, with `runner.max_concurrency(1)`.

**A `.env` file in the project changes your tests.** *Symptom:* a test sets `DATABASE_URL`, but `load_settings` returns the value from your local `.env` file. *Fix:* `load_dotenv()` sets every variable in the file, and a value in the file replaces a value that is already set. Call `config.load_dotenv()` in `main` before `load_settings()`, not inside it, so that the tests of `load_settings` never read the file.

**The app starts from another directory.** *Symptom:* the app works with `gleam run` in the project, but reports a missing variable when you start it from somewhere else. *Fix:* `load_dotenv()` reads `.env` in the current working directory, and returns `Ok(Nil)` when it is not there. Start the app from the directory that holds the file, or load the file by its full path with `load_dotenv_from(path)`.

## Where to go next

- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): the file format, a second file for secrets, and the errors for a bad file.
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md): defaults, numbers that must be valid, ranges, and the values that `get_bool` accepts.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): every function of `dream_config/loader`.
