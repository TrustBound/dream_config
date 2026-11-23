# Use a .env file in development

In production, the platform sets your app's environment variables: systemd, Docker, Kubernetes or your host's dashboard. On your laptop, nobody does. You can type `DATABASE_URL=... PORT=... gleam run` every time, or keep the values in a `.env` file that the app reads when it starts. This guide shows how to load that file, and which value wins when a variable is in the file and in the environment. It also shows how to load a second file such as a secrets file, what the file format allows, and what happens when the file is bad.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Write a .env file](#step-1-write-a-env-file)
- [Step 2: Load it at startup](#step-2-load-it-at-startup)
- [Step 3: Let the file win when you need it](#step-3-let-the-file-win-when-you-need-it)
- [Step 4: Load a second file from a path](#step-4-load-a-second-file-from-a-path)
- [Which value wins](#which-value-wins)
- [Which file for which situation](#which-file-for-which-situation)
- [The file format](#the-file-format)
- [When the file is bad](#when-the-file-is-bad)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Write a `.env` file for local development and keep it out of git.
- Load it at startup with code that also runs in production, where there is no file, and where the platform's values must win.
- Let the file win over the environment in the cases where you need that.
- Load a second file from a path, such as a secrets file that the platform mounts.
- Stop with a clear message when a file is bad.
- Test code that loads a `.env` file.

## Before you start

Add the package to your project:

```sh
gleam add dream_config
```

The examples import `dream_config/loader` as `config`. If you have not read settings with dream_config before, start with [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md). This guide is about the file.

## Step 1: Write a .env file

Make a file named `.env` in the root of your project, next to `gleam.toml`:

### A .env file for local development <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/fixtures/guide_development.env"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```dotenv
# Settings for local development. Keep this file out of git.
DATABASE_URL=postgres://localhost:5432/myapp_dev
PORT=8080
DEBUG=true
```

Each line is `NAME=VALUE`. A line that starts with `#` is a comment. The [file format](#the-file-format) section shows the rest of the rules.

Then add a line with `.env` to your `.gitignore`, because the file often holds passwords and keys.

## Step 2: Load it at startup

Call `config.load_dotenv()` before you read any setting:

### Load the .env file at startup <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_at_startup() -> Result(String, String) {
  // A missing .env file is not an error, a malformed one is
  use _ <- result.try(
    config.load_dotenv() |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
```

`load_dotenv()` reads `.env` in the current working directory. For each variable of the file, it sets the variable in the environment of the BEAM if the variable is not set yet. After that, `get_required` and the other functions see those values as if the shell had set them. `load_dotenv()` returns a `LoadError` for a bad file, and `config.describe_load_error` turns it into text, so the function can return one `String` error for both problems.

With the file from Step 1 and no `DATABASE_URL` in the environment, `database_url_at_startup()` returns the value from the file:

### The value from the .env file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_env_files_step_2_file_value.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok("postgres://localhost:5432/myapp_dev")
```

The same code runs in production. When there is no `.env` file, `load_dotenv()` returns `Ok(Nil)` and sets nothing. With `DATABASE_URL=postgres://db.internal:5432/myapp` set by the platform and no file, the function returns:

### The value from the environment, with no file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_env_files_step_2_no_file.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok("postgres://db.internal:5432/myapp")
```

When the variable is in the environment and in the file, the environment wins. With `DATABASE_URL=postgres://db.internal:5432/myapp` in the environment and the file from Step 1, the function returns the value from the environment:

### The value from the environment, with a file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_env_files_step_2_environment_wins.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok("postgres://db.internal:5432/myapp")
```

So a value that the platform sets is never replaced by a `.env` file that reached the machine by mistake. A variable that is set to an empty string is also set: the file does not replace it either.

## Step 3: Let the file win when you need it

Sometimes the file must win. Your shell exported `DATABASE_URL` for another project, and you want this project's `.env` file to decide. Or a tool loads a profile file on purpose, and its values must replace the ones that are set. For these cases, use `load_dotenv_override()`:

### Let the .env file win <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/doc_load_dotenv_override.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_from_file() -> Result(String, String) {
  // The value in the .env file replaces a variable that is already set
  use _ <- result.try(
    config.load_dotenv_override()
    |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
```

`load_dotenv_override()` reads the same file and sets every variable of it. A value in the file replaces a variable that is already set. With `DATABASE_URL=postgres://db.internal:5432/myapp` in the environment and the file from Step 1, `database_url_from_file()` returns the value from the file:

### The value from the file that wins <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/outputs/guide_env_files_step_3_file_wins.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Ok("postgres://localhost:5432/myapp_dev")
```

`load_dotenv_override_from(path)` does the same for a file at a path. Use the override functions only for development tools and tests, never where the platform sets the values.

## Step 4: Load a second file from a path

Some platforms give your app its secrets as a file, for example a Docker or Kubernetes secret mounted at `/run/secrets/myapp.env`. That file has the same format. Load it by its path with `load_dotenv_from`:

### Load two files <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/readme_load_env_files.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader.{type LoadError} as config
import gleam/result

pub fn load_env_files(secrets_path: String) -> Result(Nil, LoadError) {
  // The first value for a name wins, so load the most important file first
  use _ <- result.try(config.load_dotenv_from(secrets_path))

  // Then the local .env file, for the names that are still not set
  config.load_dotenv()
}
```

`load_env_files("/run/secrets/myapp.env")` loads the secrets file first, and then `.env`, if it is there. Each load sets only the variables that are not set yet, so the first value for a name wins: the environment first, then the secrets file, then `.env`. Load the most important file first.

With this secrets file:

### A secrets file <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/fixtures/guide_secrets.env"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```dotenv
DATABASE_URL=postgres://db.internal:5432/myapp
API_KEY=secret-from-the-platform
```

`config.get("API_KEY")` returns `Ok("secret-from-the-platform")`. When the `.env` file from Step 1 is also there, `config.get("DATABASE_URL")` returns `Ok("postgres://db.internal:5432/myapp")`, from the secrets file, and `config.get("PORT")` returns `Ok("8080")`, from `.env`, because the secrets file has no `PORT`.

There is one difference between the two functions. `load_dotenv()` treats a missing `.env` as "nothing to load". `load_dotenv_from(path)` treats a missing file as an error, because you named the file, so you expect it to be there.

## Which value wins

| The variable is | `load_dotenv()`, `load_dotenv_from(path)` | `load_dotenv_override()`, `load_dotenv_override_from(path)` |
|:---|:---|:---|
| Not set | The value in the file | The value in the file |
| Set, for example by the platform | The value that is set | The value in the file |
| Set to an empty string | The empty string | The value in the file |
| On two lines of the file | The last line of the file, if the variable was not set | The last line of the file |

## Which file for which situation

| Your situation | Use | Why |
|:---|:---|:---|
| Local development | A `.env` file and `load_dotenv()` | Each developer keeps their own values, out of git. |
| Production, CI | Real environment variables, no file | The platform owns the values. `load_dotenv()` finds no file and does nothing. If a file is there, the platform's values still win. |
| A platform that mounts secrets as a file | `load_dotenv_from(path)` | A missing file is an error, so a broken mount stops the app. |
| A file that is sometimes there | `load_dotenv()` from the directory that holds it | Only `.env` in the current directory is optional. |
| A file that must replace the values that are set | `load_dotenv_override()` or `load_dotenv_override_from(path)` | The file wins. Use it in development tools and tests only. |

## The file format

These lines are from a test file, and the value column is what `config.get(name)` returns after the file loads:

| Line in the file | `config.get` returns | Rule |
|:---|:---|:---|
| `# A comment line` | nothing is set | A line that starts with `#` is a comment. Empty lines are skipped. |
| `export EXPORTED=yes` | `get("EXPORTED")` is `Ok("yes")` | An `export ` before the name has no effect, so a shell can source the same file. |
| `lower_name=abc` | `get("LOWER_NAME")` is `Ok("abc")`, `get("lower_name")` is `Error(NotSet("lower_name"))` | Names are changed to upper case. |
| `SPACED_VALUE =   two words   ` | `Ok("two words")` | Spaces around the name and around an unquoted value are removed. |
| `PASSWORD=abc#def` | `Ok("abc")` | A `#` ends an unquoted value. The rest is a comment. |
| `QUOTED_PASSWORD="abc#def"` | `Ok("abc#def")` | In quotes, a `#` is part of the value. |
| `URL=postgres://user:secret@db/app?sslmode=require` | `Ok("postgres://user:secret@db/app?sslmode=require")` | The name ends at the first `=`. Later `=` signs are part of the value. |
| `EMPTY=` | `Ok("")` | An empty value sets the variable to an empty string. |
| `REFERENCE=${URL}` | `Ok("${URL}")` | A reference to another variable is not expanded. |
| `REPEATED=first`, then `REPEATED=second` | `Ok("second")` | The last line for a name wins. |
| `DOUBLE_QUOTED="one\ntwo"` | `Ok("one\ntwo")`, with a line break | In double quotes, `\n` is a line break. |
| `SINGLE_QUOTED='one\ntwo'` | `Ok("one\\ntwo")`, a backslash and an `n` | In single quotes, `\n` stays as written. |

A value in double quotes, single quotes or backticks can also run over several lines. This value is `"first line\nsecond line"`:

### A value over two lines <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/fixtures/guide_format.env#L14-L15"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```dotenv
MULTILINE="first line
second line"
```

In each kind of quote, a backslash before the quote character puts that character in the value. After the closing quote, only spaces and a `#` comment can follow on the same line. Windows line endings (`\r\n`) work as well. Some Windows editors save UTF-8 with a byte order mark (the bytes `EF BB BF`) at the start of the file. The reader skips that mark, so the first name of the file reads as usual.

## When the file is bad

All four load functions return `Error(LoadError)` for a bad file. The error holds the path and, for a bad line, the line number. On an error, no variable from the file is set, not even the lines before the bad one. These are the real errors for `load_env_files` from Step 4, each for a test file with that problem, and the text that `config.describe_load_error` gives for each:

| Problem | Error | `describe_load_error` gives |
|:---|:---|:---|
| The file does not exist | `FileNotFound("test/fixtures/does_not_exist.env")` | `Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist` |
| A line has no `=` | `MissingEquals("test/fixtures/missing_equals.env", 2)` | `Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE` |
| A quote is not closed | `QuoteNotClosed("test/fixtures/unclosed_quote.env", 1, DoubleQuote)` | `Cannot load .env file at test/fixtures/unclosed_quote.env: line 1: the double quote is not closed` |
| The file is not UTF-8 | `FileNotUtf8("test/fixtures/not_utf8.env")` | `Cannot load .env file at test/fixtures/not_utf8.env: the file is not valid UTF-8` |
| The file cannot be read | `FileNotReadable("build/guide_env_files_unreadable.env", "permission denied")` | `Cannot load .env file at build/guide_env_files_unreadable.env: permission denied` |

`FileNotFound` comes only from `load_dotenv_from` and `load_dotenv_override_from`. Two more errors are for a bad line: `EmptyName(path, line)` for a line such as `=value`, and `TextAfterClosingQuote(path, line, quote)` for text after a closing quote. For a quote that is not closed, the line number is the line of the opening quote.

You need no special code for these. Turn the error into text with `describe_load_error` and pass it up with `result.try`, as the snippet in Step 2 does, and let `main` print it and stop, as [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md#step-3-load-the-env-file-and-the-settings-once-in-main) shows. Match on the error only when your code must act on one cause, for example to show a hint for `FileNotFound`.

## Test your code

To test code that calls `load_dotenv()`, write the `.env` file in the test, run your code, and delete the file after. Here is a test module for `database_url_at_startup` from Step 2. It uses [dream_test](https://hexdocs.pm/dream_test), whose `file` module writes and deletes files:

### Test code that loads .env <a href="https://github.com/TrustBound/dream_config/blob/2.0.0/test/snippets/guide_env_files_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import gleam/result
import snippets/doc_load_dotenv.{database_url_at_startup}

pub fn tests() -> TestSuite {
  describe("database_url_at_startup", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      file.delete(".env")
      |> result.map_error(file.error_to_string)
    }),
    it("reads DATABASE_URL from the .env file", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/test\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://localhost/test"))
      |> or_fail_with("Expected the value from the .env file")
    }),
    it("keeps a DATABASE_URL that is already set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://ci-database/test")
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/test\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://ci-database/test"))
      |> or_fail_with("Expected the value from the environment")
    }),
    it("stops at a line that is not valid", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Error(
        "Cannot load .env file at .env: line 1: expected NAME=VALUE",
      ))
      |> or_fail_with("Expected the line number and the reason")
    }),
  ])
}
```

The tests run in the project root, so `.env` there is the file that `load_dotenv()` reads. The `after_each` hook deletes it and unsets `DATABASE_URL`, so a test never sees a file or a value from the test before it. `file.delete` returns `Ok(Nil)` when the file is not there, so the hook also works after a test that did not write one. The second test sets `DATABASE_URL` and writes a file with another value, and expects the value that is set.

Two cautions:

- These tests delete `.env` in the project root. If you keep your own `.env` there, the tests delete it. Run them from a directory that holds no file you need, or test with `load_dotenv_from` and a file under `build/`.
- Environment variables and the current directory belong to the whole BEAM. Run these tests one at a time, with `runner.max_concurrency(1)` in dream_test.

## Common pitfalls

**A change in `.env` has no effect.** *Symptom:* you change `DATABASE_URL` in `.env`, but the app still uses the old value. *Fix:* a variable that is set wins over the file, and your shell exported `DATABASE_URL` earlier. Run `unset DATABASE_URL` in the shell, or load the file with `load_dotenv_override()` in a development tool.

**A `.env` file in production.** *Symptom:* production uses a development value, for example `DEBUG=true`, for a setting that the platform does not set. *Fix:* the platform's values win over the file. But a variable that the platform does not set comes from the file. Keep `.env` out of your images and releases, for example with a `.dockerignore` line.

**A `#` in a password.** *Symptom:* the database refuses the password, but the line in `.env` looks right. *Fix:* in an unquoted value, a `#` starts a comment, so `PASSWORD=abc#def` sets `abc`. Put the value in quotes: `PASSWORD="abc#def"`.

**A lower-case name.** *Symptom:* `config.get("database_url")` returns `Error(NotSet("database_url"))` after the file loads. *Fix:* names in the file are changed to upper case. Read `DATABASE_URL`.

**Expecting `${NAME}` to expand.** *Symptom:* a value holds the literal text `${URL}`. *Fix:* the file has no variable expansion. Write the full value, or build it in your code from two settings.

**An optional second file.** *Symptom:* the app stops with `the file does not exist` on a machine that has no such file. *Fix:* `load_dotenv_from(path)` requires the file. Call it only where the file must be there.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): read your settings into a typed record and stop with a message when one is missing.
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md): defaults that do not hide a typo, and the values that `get_bool` accepts.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): `load_dotenv`, `load_dotenv_override`, `LoadError` and the rest of `dream_config/loader`.
