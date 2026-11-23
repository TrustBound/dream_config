# Use a .env file in development

In production, the platform sets your app's environment variables: systemd, Docker, Kubernetes or your host's dashboard. On your laptop, nobody does. You can type `DATABASE_URL=... PORT=... gleam run` every time, or keep the values in a `.env` file that the app reads when it starts. This guide shows how to load that file, how to load a second file such as a secrets file, what the file format allows, and what happens when the file is bad.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Write a .env file](#step-1-write-a-env-file)
- [Step 2: Load it at startup](#step-2-load-it-at-startup)
- [Step 3: Load a second file from a path](#step-3-load-a-second-file-from-a-path)
- [Which file for which situation](#which-file-for-which-situation)
- [The file format](#the-file-format)
- [When the file is bad](#when-the-file-is-bad)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Write a `.env` file for local development and keep it out of git.
- Load it at startup with code that also runs in production, where there is no file.
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

```sh
# Settings for local development. Keep this file out of git.
DATABASE_URL=postgres://localhost:5432/myapp_dev
PORT=8080
DEBUG=true
```

Each line is `NAME=VALUE`. A line that starts with `#` is a comment. The [file format](#the-file-format) section shows the rest of the rules.

Then add `.env` to your `.gitignore`, because it often holds passwords and keys:

```sh
.env
```

## Step 2: Load it at startup

Call `config.load_dotenv()` before you read any setting:

### Load the .env file at startup <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/doc_load_dotenv.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_config/loader as config
import gleam/result

pub fn database_url_at_startup() -> Result(String, String) {
  // A missing .env file is not an error, a malformed one is
  use _ <- result.try(config.load_dotenv())
  config.get_required("DATABASE_URL")
}
```

`load_dotenv()` reads `.env` in the current working directory and sets each variable in it in the environment of the BEAM. After that, `get_required` and the other functions see those values as if the shell had set them.

With the file from Step 1, `database_url_at_startup()` returns:

```text
Ok("postgres://localhost:5432/myapp_dev")
```

The same code runs in production. When there is no `.env` file, `load_dotenv()` returns `Ok(Nil)` and sets nothing. With `DATABASE_URL=postgres://db.internal:5432/myapp` set by the platform and no file, the function returns:

```text
Ok("postgres://db.internal:5432/myapp")
```

Know which value wins when both are there. A value in the file replaces a variable that is already set. With `DATABASE_URL=postgres://db.internal:5432/myapp` in the environment and the file from Step 1, the function returns the value from the file:

```text
Ok("postgres://localhost:5432/myapp_dev")
```

So a `.env` file must never reach a production machine. Keep it out of your container image and your release, for example with a `.dockerignore` line.

## Step 3: Load a second file from a path

Some platforms give your app its secrets as a file, for example a Docker or Kubernetes secret mounted at `/run/secrets/myapp.env`. That file has the same format. Load it by its path with `load_dotenv_from`:

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

`load_env_files("/run/secrets/myapp.env")` loads `.env` first, if it is there, and then the file at the path. Because a later value replaces an earlier one, the file you load last wins.

With this secrets file:

```sh
DATABASE_URL=postgres://db.internal:5432/myapp
API_KEY=secret-from-the-platform
```

`config.get("API_KEY")` returns `Ok("secret-from-the-platform")`. When the `.env` file from Step 1 is also there, `config.get("DATABASE_URL")` returns `Ok("postgres://db.internal:5432/myapp")`, from the secrets file.

There is one difference between the two functions. `load_dotenv()` treats a missing `.env` as "nothing to load". `load_dotenv_from(path)` treats a missing file as an error, because you named the file, so you expect it to be there.

## Which file for which situation

| Your situation | Use | Why |
|:---|:---|:---|
| Local development | A `.env` file and `load_dotenv()` | Each developer keeps their own values, out of git. |
| Production, CI | Real environment variables, no file | The platform owns the values. `load_dotenv()` finds no file and does nothing. |
| A platform that mounts secrets as a file | `load_dotenv_from(path)` | A missing file is an error, so a broken mount stops the app. |
| A file that is sometimes there | `load_dotenv()` from the directory that holds it | Only `.env` in the current directory is optional. |

## The file format

These lines are from a test file, and the value column is what `config.get(name)` returns after the file loads:

| Line in the file | `config.get` returns | Rule |
|:---|:---|:---|
| `# A comment line` | nothing is set | A line that starts with `#` is a comment. Empty lines are skipped. |
| `export EXPORTED=yes` | `get("EXPORTED")` is `Ok("yes")` | An `export ` before the name has no effect, so a shell can source the same file. |
| `lower_name=abc` | `get("LOWER_NAME")` is `Ok("abc")`, `get("lower_name")` is `Error(Nil)` | Names are changed to upper case. |
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

```sh
MULTILINE="first line
second line"
```

In each kind of quote, a backslash before the quote character puts that character in the value. After the closing quote, only spaces and a `#` comment can follow on the same line. Windows line endings (`\r\n`) work as well.

## When the file is bad

Both functions return `Error(String)` with the path, the reason and, for a bad line, the line number. On an error, no variable from the file is set, not even the lines before the bad one. These are the real messages, each for a test file with that problem:

```text
Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist
Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE
Cannot load .env file at test/fixtures/unclosed_quote.env: line 1: the double quote is not closed
Cannot load .env file at test/fixtures/not_utf8.env: the file is not valid UTF-8
Cannot load .env file at build/guide_env_files_unreadable.env: permission denied
```

The first one comes only from `load_dotenv_from`. A line with no `=`, a line with an empty name, a quote that is not closed, and text after a closing quote all give a line error. For a quote that is not closed, the line number is the line of the opening quote.

You need no special code for these. Pass the error up with `result.try`, as all the snippets in this guide do, and let `main` print it and stop, as [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md#step-3-load-the-settings-once-in-main) shows.

## Test your code

To test code that calls `load_dotenv()`, write the `.env` file in the test, run your code, and delete the file after. Here is a test module for `database_url_at_startup` from Step 2. It uses [dream_test](https://hexdocs.pm/dream_test), whose `file` module writes and deletes files:

### Test code that loads .env <a href="https://github.com/TrustBound/dream_config/blob/1.1.0/test/snippets/guide_env_files_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

The tests run in the project root, so `.env` there is the file that `load_dotenv()` reads. The `after_each` hook deletes it and unsets `DATABASE_URL`, so a test never sees a file or a value from the test before it. `file.delete` returns `Ok(Nil)` when the file is not there, so the hook also works after a test that did not write one.

Two cautions:

- These tests delete `.env` in the project root. If you keep your own `.env` there, the tests delete it. Run them from a directory that holds no file you need, or test with `load_dotenv_from` and a file under `build/`.
- Environment variables and the current directory belong to the whole BEAM. Run these tests one at a time, with `runner.max_concurrency(1)` in dream_test.

## Common pitfalls

**A `#` in a password.** *Symptom:* the database refuses the password, but the line in `.env` looks right. *Fix:* in an unquoted value, a `#` starts a comment, so `PASSWORD=abc#def` sets `abc`. Put the value in quotes: `PASSWORD="abc#def"`.

**A lower-case name.** *Symptom:* `config.get("database_url")` returns `Error(Nil)` after the file loads. *Fix:* names in the file are changed to upper case. Read `DATABASE_URL`.

**A `.env` file in production.** *Symptom:* production talks to the development database, although the platform sets `DATABASE_URL` correctly. *Fix:* a value in the file replaces the variable that the platform set. Keep `.env` out of your images and releases.

**A file saved with a byte order mark.** *Symptom:* every variable in the file is set except the first one. *Fix:* some Windows editors save UTF-8 with a byte order mark at the start of the file. Today dream_config keeps that mark as part of the first name, so `get` cannot find it. Save the file as UTF-8 without the mark.

**Expecting `${NAME}` to expand.** *Symptom:* a value holds the literal text `${URL}`. *Fix:* the file has no variable expansion. Write the full value, or build it in your code from two settings.

**An optional second file.** *Symptom:* the app stops with `the file does not exist` on a machine that has no such file. *Fix:* `load_dotenv_from(path)` requires the file. Call it only where the file must be there.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_config/blob/main/docs/guides/getting-started.md): read your settings into a typed record and stop with a message when one is missing.
- [Read optional settings, numbers and flags](https://github.com/TrustBound/dream_config/blob/main/docs/guides/typed-values.md): defaults, numbers that must be valid, and the values that `get_bool` accepts.
- [API reference on HexDocs](https://hexdocs.pm/dream_config/dream_config/loader.html): `load_dotenv`, `load_dotenv_from` and the rest of `dream_config/loader`.
