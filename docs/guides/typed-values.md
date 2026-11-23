# Read optional settings, numbers and flags

Not every setting is a required string. A port has a default. An API key may be absent in development. A debug switch is on or off. A pool size must be a number in a range. Each of these needs a slightly different read. The trap is the same for all of them: a typo must stop the app, not fall back to the default without a sound. This guide shows the read for each kind of setting, and how dream_config's error type keeps "not set" apart from "set but wrong".

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Give an optional number a default](#step-1-give-an-optional-number-a-default)
- [Step 2: Read an optional string](#step-2-read-an-optional-string)
- [Step 3: Read on or off switches](#step-3-read-on-or-off-switches)
- [Step 4: Check that a number is in a range](#step-4-check-that-a-number-is-in-a-range)
- [Which read to use](#which-read-to-use)
- [What counts as an integer](#what-counts-as-an-integer)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Read an optional number with a default that applies only when the variable is not set, and stop on a value that is wrong.
- Read an optional string as an `Option`.
- Read on or off switches, and know exactly which values count as on.
- Check that a required number is in a range.
- Test each case of an optional setting.

## Before you start

Add the package to your project:

```sh
gleam add dream_config
```

The examples import `dream_config/loader` as `config`. They read real environment variables, so set them in the shell where you run the code, for example `PORT=8080 gleam run`. [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md) shows how these reads fit into a settings record that you load in `main`.

Every read function returns the same error type, `ConfigError`. It has three variants: `NotSet(name)` for a variable that is not set, `NotAnInteger(name, value)` for a value that is not an integer, and `Empty(name)` for a required variable that is set to an empty string.

## Step 1: Give an optional number a default

Read an optional number with `get_int`, and match on the error. Use the default only for `NotSet`, and pass every other result on:

### Use a default only when the setting is not set <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_typed_values_port.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{type ConfigError, NotSet} as config

pub fn port() -> Result(Int, ConfigError) {
  case config.get_int("PORT") {
    Error(NotSet(_)) -> Ok(3000)
    other -> other
  }
}
```

`get_int("PORT")` returns `Error(NotSet("PORT"))` when the variable is not set, and `port()` returns `Ok(3000)`. With `PORT=8080`, it returns `Ok(8080)`. With `PORT=eighty`, `get_int` returns a different error, and `port()` passes it on:

```text
Error(NotAnInteger("PORT", "eighty"))
```

An empty value is not an integer either. With `PORT` set to an empty string, `port()` returns:

```text
Error(NotAnInteger("PORT", ""))
```

The result is a `Result(Int, ConfigError)`, the same type as the required reads, so `port()` fits into the `result.try` chain of your settings loader. When the app stops, `config.describe` gives the text for the error. For `PORT=eighty`, that is:

```text
Environment variable PORT must be an integer
```

Do not write `config.get_int("PORT") |> result.unwrap(3000)`. `result.unwrap` throws every error away, `NotAnInteger` too. With `PORT=eighty`, it returns `3000`, and the app listens on a port that nobody asked for.

## Step 2: Read an optional string

Use `get` for an optional string. Its only error is `NotSet`, so a short `case` or `option.from_result` is enough:

### Read an optional value <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_get.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/option.{type Option}

pub fn api_key() -> Option(String) {
  case config.get("API_KEY") {
    Ok(key) -> option.Some(key)
    Error(_) -> option.None
  }
}
```

With `API_KEY=example-api-key`, `api_key()` returns `Some("example-api-key")`. With no `API_KEY`, it returns `None`. Keep the `Option` when the rest of your code must know that there is no key, for example to turn off a feature. Use `result.unwrap("default")` on `config.get(name)` when a default is enough.

An empty value is a value. With `API_KEY` set to an empty string, `api_key()` returns `Some("")`. When an empty string is not valid, read the setting with `get_required`, which returns `Empty(name)` for it.

## Step 3: Read on or off switches

`get_bool` reads a switch. It never fails: it returns `True` or `False`.

### Pick a log level from DEBUG <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_boolean_values.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

These are the values that `get_bool("DEBUG")` reads, from a test that sets each one:

| `DEBUG` is | `get_bool("DEBUG")` |
|:---|:---|
| `true`, `TRUE`, `tRUE` | `True` |
| `Yes` | `True` |
| `1` | `True` |
| not set | `False` |
| `false`, `0` | `False` |
| `on`, `y` | `False` |
| `ture` | `False` |
| ` true`, with a space before it | `False` |

`true` and `yes` count in any mix of upper and lower case. Every other value is `False`, with no error. That makes `False` the safe side: a switch that turns on something risky, such as debug output or a test mode, stays off when its value is not clear. Choose names so that off is the safe state.

## Step 4: Check that a number is in a range

A number can parse and still be wrong: a pool size of 0, a timeout of -1. Read it with `get_required_int`, then check it:

### Check a pool size <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_typed_values_pool_size.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/int
import gleam/result

pub fn pool_size() -> Result(Int, String) {
  use size <- result.try(
    config.get_required_int("POOL_SIZE") |> result.map_error(config.describe),
  )
  case size >= 1 && size <= 100 {
    True -> Ok(size)
    False ->
      Error("POOL_SIZE must be from 1 to 100, got " <> int.to_string(size))
  }
}
```

`pool_size()` returns your own message for a value out of the range, so it turns the `ConfigError` into text with `config.describe` first. Then both kinds of error have the same type. It gives a different result for each kind of problem:

| `POOL_SIZE` is | `pool_size()` returns |
|:---|:---|
| `20` | `Ok(20)` |
| `0` | `Error("POOL_SIZE must be from 1 to 100, got 0")` |
| `twenty` | `Error("Environment variable POOL_SIZE must be an integer")` |
| empty | `Error("Required environment variable is empty: POOL_SIZE")` |
| not set | `Error("Required environment variable not set: POOL_SIZE")` |

Write your own message the same way: name the variable, say what is allowed, and show the value you got. dream_config has no function for floats, lists or durations. For those, read the string with `get` or `get_required`, and parse it in a small function like this one.

## Which read to use

| Your setting | Use | What happens with a bad value |
|:---|:---|:---|
| An optional string | `get(name)`, then `option.from_result` or `result.unwrap` | Any string is valid, the empty string too. |
| An optional number with a default | `get_int(name)`, and the default only for `NotSet`, as in [Step 1](#step-1-give-an-optional-number-a-default) | `NotAnInteger(name, value)`. |
| A required string | `get_required(name)` | `Empty(name)` for an empty value. |
| A required number | `get_required_int(name)` | `NotAnInteger(name, value)`, or `Empty(name)`. |
| A number with limits | `get_required_int(name)` and a check, as in [Step 4](#step-4-check-that-a-number-is-in-a-range) | Your own error. |
| An on or off switch | `get_bool(name)` | `False`. |

## What counts as an integer

`get_int` and `get_required_int` use Gleam's `int.parse`. These are the values they accept, from a test that sets `PORT` to each one:

| `PORT` is | `get_int("PORT")` |
|:---|:---|
| `8080` | `Ok(8080)` |
| `+8080` | `Ok(8080)` |
| `08080` | `Ok(8080)` |
| `-1` | `Ok(-1)` |
| ` 8080`, with a space before it | `Error(NotAnInteger("PORT", " 8080"))` |
| `8_080` | `Error(NotAnInteger("PORT", "8_080"))` |
| `0x1F` | `Error(NotAnInteger("PORT", "0x1F"))` |
| `8080.0` | `Error(NotAnInteger("PORT", "8080.0"))` |
| empty | `Error(NotAnInteger("PORT", ""))` |

A space around the value makes it fail. A `.env` file removes the spaces around an unquoted value, but a shell or a platform dashboard does not, so a value pasted with a space fails there. The error holds the value as it is, so a log line can show the space.

## Test your code

Test every case of an optional setting: not set, set and valid, and set but wrong. Here is a test module for `port()` from Step 1. It uses [dream_test](https://hexdocs.pm/dream_test):

### Test port for each case <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_typed_values_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{NotAnInteger}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/guide_typed_values_port.{port}

pub fn tests() -> TestSuite {
  describe("port", [
    after_each(fn() {
      envoy.unset("PORT")
      Ok(Nil)
    }),
    it("uses 3000 when PORT is not set", fn() {
      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Ok(3000))
      |> or_fail_with("Expected the default port")
    }),
    it("reads PORT when it is a number", fn() {
      // Arrange
      envoy.set("PORT", "8080")

      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Ok(8080))
      |> or_fail_with("Expected the port from PORT")
    }),
    it("rejects a PORT that is not a number", fn() {
      // Arrange
      envoy.set("PORT", "80a")

      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "80a")))
      |> or_fail_with("Expected an error, not the default")
    }),
  ])
}
```

The first test sets nothing. It relies on the `after_each` hook, which unsets `PORT` after every test, so no value from an earlier test is left behind. The last test expects the error value, not the default. Environment variables belong to the whole BEAM, so run these tests one at a time, with `runner.max_concurrency(1)`.

## Common pitfalls

**A typo that becomes the default.** *Symptom:* the app runs on port 3000 although you set `PORT`. *Fix:* the code reads the port with `result.unwrap(3000)`, which throws `NotAnInteger` away. Match on `NotSet` and pass the other errors on, as in [Step 1](#step-1-give-an-optional-number-a-default).

**A catch-all branch that hides an error.** *Symptom:* the same as a typo that becomes the default, with a `case` in the code. *Fix:* a branch `Error(_) -> Ok(3000)` matches every error. Write `Error(NotSet(_))` for the default.

**A switch that will not turn on.** *Symptom:* `DEBUG=on` or `DEBUG=y` has no effect. *Fix:* only `true`, `yes` and `1`, in any letter case, are `True`. Use one of those.

**An optional value that is empty.** *Symptom:* the app sends an empty API key, although the key is optional. *Fix:* `get` returns `Ok("")` for a variable that is set to an empty string, for example by an `API_KEY=` line in a `.env` file. Remove the line, or treat `Ok("")` as "no key" in your code.

**Mixing `ConfigError` and `String` in one chain.** *Symptom:* a compile error about a type mismatch when you put `config.get_required_int(name)` in a `use ... <- result.try(...)` chain with your own `String` errors. *Fix:* turn the `ConfigError` into text with `result.map_error(config.describe)`, as `pool_size` does in [Step 4](#step-4-check-that-a-number-is-in-a-range).

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): load all your settings into a typed record in `main`, and stop with a message when one is wrong.
- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): keep local values in a file, which value wins, and what the file format allows.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): `get`, `get_int`, `get_bool`, `ConfigError` and the rest of `dream_config/loader`.
