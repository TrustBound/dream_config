# Read optional settings, numbers and flags

Not every setting is a required string. A port has a default. An API key may be absent in development. A debug switch is on or off. A pool size must be a number in a range. Each of these needs a slightly different read, and each has a way to go wrong without a sound: a typo that falls back to the default, a flag that is off because you wrote `on`. This guide shows the read for each kind of setting, and how to make a bad value stop the app instead of hiding.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Read optional settings with defaults](#step-1-read-optional-settings-with-defaults)
- [Step 2: Reject a bad number in an optional setting](#step-2-reject-a-bad-number-in-an-optional-setting)
- [Step 3: Read on or off switches](#step-3-read-on-or-off-switches)
- [Step 4: Check that a number is in a range](#step-4-check-that-a-number-is-in-a-range)
- [Which read to use](#which-read-to-use)
- [What counts as an integer](#what-counts-as-an-integer)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Read an optional string as an `Option`, and an optional number with a default.
- Reject an optional number that is set but is not a number, instead of using the default.
- Read on or off switches, and know exactly which values count as on.
- Check that a required number is in a range.
- Test each case of an optional setting.

## Before you start

Add the package to your project:

```sh
gleam add dream_config
```

The examples import `dream_config/loader` as `config`. They read real environment variables, so set them in the shell where you run the code, for example `PORT=8080 gleam run`. [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md) shows how these reads fit into a settings record that you load in `main`.

## Step 1: Read optional settings with defaults

Use `get` for an optional string and `get_int` for an optional number. Both return `Error(Nil)` when the variable is not set, and you decide what that means:

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

`option.from_result` turns `Ok(key)` into `Some(key)` and `Error(Nil)` into `None`. Keep the `Option` when the rest of your code must know that there is no key, for example to turn off a feature. `result.unwrap(3000)` gives the default when there is no usable value.

With `API_KEY=example-api-key` and `PORT=8080`, `read_optional_values()` returns `#(Some("example-api-key"), 8080)`. With neither set, it returns `#(None, 3000)`.

Now set `PORT=eighty`. The function returns:

```text
#(None, 3000)
```

`get_int` returns `Error(Nil)` both for a variable that is not set and for a value that is not an integer, so the typo is gone and the app listens on port 3000. That is fine for a setting where any default is safe. For most numbers, it is not.

## Step 2: Reject a bad number in an optional setting

To treat "not set" and "set but wrong" differently, ask first whether the variable is set, and only then parse it:

### Use a default only when the setting is not set <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_typed_values_port.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config

pub fn port() -> Result(Int, String) {
  case config.get("PORT") {
    Error(Nil) -> Ok(3000)
    Ok(_) -> config.get_required_int("PORT")
  }
}
```

When `PORT` is not set, `config.get` returns `Error(Nil)`, and `port()` returns `Ok(3000)`. When it is set, `get_required_int` parses it, and a value that is not an integer gives an error that names the variable. With `PORT=eighty`, `port()` returns:

```text
Error("Environment variable PORT must be an integer")
```

The result is a `Result(Int, String)`, the same type as the required reads, so `port()` fits into the `result.try` chain of your settings loader.

## Step 3: Read on or off switches

`get_bool` reads a switch. It never fails: it returns `True` or `False`.

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

### Check a pool size <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_typed_values_pool_size.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/int
import gleam/result

pub fn pool_size() -> Result(Int, String) {
  use size <- result.try(config.get_required_int("POOL_SIZE"))
  case size >= 1 && size <= 100 {
    True -> Ok(size)
    False ->
      Error("POOL_SIZE must be from 1 to 100, got " <> int.to_string(size))
  }
}
```

`pool_size()` gives a different result for each kind of problem:

| `POOL_SIZE` is | `pool_size()` returns |
|:---|:---|
| `20` | `Ok(20)` |
| `0` | `Error("POOL_SIZE must be from 1 to 100, got 0")` |
| `twenty` | `Error("Environment variable POOL_SIZE must be an integer")` |
| not set | `Error("Required environment variable not set: POOL_SIZE")` |

Write your own message the same way: name the variable, say what is allowed, and show the value you got. dream_config has no function for floats, lists or durations. For those, read the string with `get` or `get_required`, and parse it in a small function like this one.

## Which read to use

| Your setting | Use | What happens with a bad value |
|:---|:---|:---|
| An optional string | `get(name)`, then `option.from_result` or `result.unwrap` | Any string is valid. |
| An optional number where any default is safe | `get_int(name) \|> result.unwrap(default)` | The default is used. |
| An optional number that must be valid when set | `get(name)`, then `get_required_int(name)`, as in [Step 2](#step-2-reject-a-bad-number-in-an-optional-setting) | An error that names the variable. |
| A required number | `get_required_int(name)` | An error that names the variable. |
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
| ` 8080`, with a space before it | `Error(Nil)` |
| `8_080` | `Error(Nil)` |
| `0x1F` | `Error(Nil)` |
| `8080.0` | `Error(Nil)` |
| empty | `Error(Nil)` |

A space around the value makes it fail. A `.env` file removes the spaces around an unquoted value, but a shell or a platform dashboard does not, so a value pasted with a space fails there.

## Test your code

Test every case of an optional setting: not set, set and valid, and set but wrong. Here is a test module for `port()` from Step 2. It uses [dream_test](https://hexdocs.pm/dream_test):

### Test port for each case <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_typed_values_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
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
      |> be_equal(Error("Environment variable PORT must be an integer"))
      |> or_fail_with("Expected an error, not the default")
    }),
  ])
}
```

The first test sets nothing. It relies on the `after_each` hook, which unsets `PORT` after every test, so no value from an earlier test is left behind. Environment variables belong to the whole BEAM, so run these tests one at a time, with `runner.max_concurrency(1)`.

## Common pitfalls

**A typo that becomes the default.** *Symptom:* the app runs on port 3000 although you set `PORT`. *Fix:* `get_int` returns `Error(Nil)` for a value that is not an integer, and `result.unwrap` turns that into the default. Use the read from [Step 2](#step-2-reject-a-bad-number-in-an-optional-setting).

**A switch that will not turn on.** *Symptom:* `DEBUG=on` or `DEBUG=y` has no effect. *Fix:* only `true`, `yes` and `1`, in any letter case, are `True`. Use one of those.

**An empty required value.** *Symptom:* the app starts, and fails later with an empty database URL. *Fix:* `get_required` returns `Ok("")` for a variable that is set to an empty string, for example by a `DATABASE_URL=` line in a `.env` file. When an empty string is not valid, check the value in a small function, in the same way as the range check in [Step 4](#step-4-check-that-a-number-is-in-a-range).

**Mixing `Error(Nil)` and `Error(String)` in one chain.** *Symptom:* a compile error about a type mismatch when you put `config.get(name)` in a `use ... <- result.try(...)` chain with the required reads. *Fix:* the optional reads return `Result(_, Nil)` and the required reads return `Result(_, String)`. Turn an optional read into a value first, with `result.unwrap` or `option.from_result`, or give it a message with `result.replace_error`.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): load all your settings into a typed record in `main`, and stop with a message when one is wrong.
- [Use a .env file in development](https://github.com/TrustBound/dream_config/blob/main/docs/guides/env-files.md): keep local values in a file, and what the file format allows.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): `get`, `get_int`, `get_bool` and the rest of `dream_config/loader`.
