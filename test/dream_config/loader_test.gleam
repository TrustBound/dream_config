//// Tests for `dream_config/loader`.
////
//// The tests set the environment variables they read. `after_each` unsets
//// every variable that a test can set and deletes the files that a test can
//// write, so each test starts from the same state.

import dream_config/loader.{
  Backtick, DoubleQuote, Empty, EmptyName, FileNotFound, FileNotReadable,
  FileNotUtf8, MissingEquals, NotAnInteger, NotSet, QuoteNotClosed, SingleQuote,
  TextAfterClosingQuote,
}
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import fixtures/test_file
import gleam/list
import gleam/result
import gleam/string

const variable = "DREAM_CONFIG_TEST_VALUE"

const greeting = "DREAM_CONFIG_SNIPPET_GREETING"

const good_name = "DREAM_CONFIG_TEST_GOOD_NAME"

const repeated = "DREAM_CONFIG_TEST_REPEATED"

const precedence_path = "test/fixtures/precedence.env"

const byte_order_mark_path = "test/fixtures/byte_order_mark.env"

const unreadable_path = "build/dream_config_unreadable_test.env"

const default_path = ".env"

const bad_line_path = "build/dream_config_bad_line_test.env"

pub fn tests() -> TestSuite {
  describe("dream_config/loader", [
    after_each(fn() {
      envoy.unset(variable)
      envoy.unset(greeting)
      envoy.unset(good_name)
      envoy.unset(repeated)
      use _ <- result.try(test_file.delete_if_present(unreadable_path))
      use _ <- result.try(test_file.delete_if_present(bad_line_path))
      test_file.delete_if_present(default_path)
    }),
    group("get", [
      it("returns the value when the variable is set", fn() {
        // Arrange
        envoy.set(variable, "some value")

        // Act
        let result = loader.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("some value"))
        |> or_fail_with("get should return the value of a set variable")
      }),
      it("returns NotSet when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get should return NotSet for a missing variable")
      }),
    ]),
    group("get_required", [
      it("returns the value when the variable is set", fn() {
        // Arrange
        envoy.set(variable, "postgres://localhost/app")

        // Act
        let result = loader.get_required(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("postgres://localhost/app"))
        |> or_fail_with("get_required should return the value")
      }),
      it("returns an error with the name when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get_required(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get_required should name the missing variable")
      }),
    ]),
    group("get_int", [
      it("returns the integer when the value is an integer", fn() {
        // Arrange
        envoy.set(variable, "8080")

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok(8080))
        |> or_fail_with("get_int should parse 8080")
      }),
      it("returns a negative integer when the value is negative", fn() {
        // Arrange
        envoy.set(variable, "-5")

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok(-5))
        |> or_fail_with("get_int should parse -5")
      }),
      it("returns NotAnInteger when the value is not an integer", fn() {
        // Arrange
        envoy.set(variable, "eighty")

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotAnInteger("DREAM_CONFIG_TEST_VALUE", "eighty")))
        |> or_fail_with("get_int should reject eighty")
      }),
      it("returns NotAnInteger when the value is empty", fn() {
        // Arrange
        envoy.set(variable, "")

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotAnInteger("DREAM_CONFIG_TEST_VALUE", "")))
        |> or_fail_with("get_int should reject an empty value")
      }),
      it("returns NotSet when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get_int should return NotSet for a missing variable")
      }),
    ]),
    group("get_required_int", [
      it("returns the integer when the value is an integer", fn() {
        // Arrange
        envoy.set(variable, "8080")

        // Act
        let result = loader.get_required_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok(8080))
        |> or_fail_with("get_required_int should parse 8080")
      }),
      it(
        "returns an error with the name when the value is not an integer",
        fn() {
          // Arrange
          envoy.set(variable, "eighty")

          // Act
          let result = loader.get_required_int(variable)

          // Assert
          result
          |> should
          |> be_equal(Error(NotAnInteger("DREAM_CONFIG_TEST_VALUE", "eighty")))
          |> or_fail_with("get_required_int should reject eighty")
        },
      ),
      it("returns an error with the name when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get_required_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get_required_int should name the missing variable")
      }),
    ]),
    group(
      "get_bool",
      list.flatten([
        list.map(
          ["true", "True", "TRUE", "tRUE", "yes", "Yes", "YES", "yEs", "1"],
          fn(value) {
            it("returns True for " <> value, fn() {
              // Arrange
              envoy.set(variable, value)

              // Act
              let result = loader.get_bool(variable)

              // Assert
              result
              |> should
              |> be_equal(True)
              |> or_fail_with("get_bool should read " <> value <> " as True")
            })
          },
        ),
        list.map(
          ["false", "FALSE", "0", "no", "No", "", "on", " true", "yes ", "2"],
          fn(value) {
            it("returns False for \"" <> value <> "\"", fn() {
              // Arrange
              envoy.set(variable, value)

              // Act
              let result = loader.get_bool(variable)

              // Assert
              result
              |> should
              |> be_equal(False)
              |> or_fail_with("get_bool should read " <> value <> " as False")
            })
          },
        ),
        [
          it("returns False when the variable is not set", fn() {
            // Arrange
            envoy.unset(variable)

            // Act
            let result = loader.get_bool(variable)

            // Assert
            result
            |> should
            |> be_equal(False)
            |> or_fail_with(
              "get_bool should return False for a missing variable",
            )
          }),
        ],
      ]),
    ),
    group("load_dotenv_from", [
      it("returns Ok(Nil) for a valid file", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/myapp.env")

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_dotenv_from should load a valid file")
      }),
      it("sets the variables of a valid file", fn() {
        // Arrange
        envoy.unset(greeting)
        use _ <- result.try(
          described(loader.load_dotenv_from("test/fixtures/myapp.env")),
        )

        // Act
        let result = envoy.get(greeting)

        // Assert
        result
        |> should
        |> be_equal(Ok("hello from myapp.env"))
        |> or_fail_with("load_dotenv_from should set the variable")
      }),
      it("returns an error when the file does not exist", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/does_not_exist.env")

        // Assert
        result
        |> should
        |> be_equal(Error(FileNotFound("test/fixtures/does_not_exist.env")))
        |> or_fail_with("load_dotenv_from should report a missing file")
      }),
      it("returns an error when the path is a directory", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures")

        // Assert
        result
        |> should
        |> be_equal(
          Error(FileNotReadable(
            "test/fixtures",
            "illegal operation on a directory",
          )),
        )
        |> or_fail_with("load_dotenv_from should report a directory")
      }),
      it("returns an error when the file cannot be read", fn() {
        // Arrange
        use _ <- result.try(
          file.write(unreadable_path, "DREAM_CONFIG_TEST_VALUE=1\n")
          |> result.map_error(file.error_to_string),
        )
        use _ <- result.try(
          test_file.make_unreadable(unreadable_path)
          |> result.replace_error("Cannot make the test file unreadable"),
        )

        // Act
        let result = loader.load_dotenv_from(unreadable_path)

        // Assert
        result
        |> should
        |> be_equal(
          Error(FileNotReadable(
            "build/dream_config_unreadable_test.env",
            "permission denied",
          )),
        )
        |> or_fail_with("load_dotenv_from should report a file it cannot read")
      }),
      it("returns an error when the file is not UTF-8", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/not_utf8.env")

        // Assert
        result
        |> should
        |> be_equal(Error(FileNotUtf8("test/fixtures/not_utf8.env")))
        |> or_fail_with(
          "load_dotenv_from should report a file that is not UTF-8",
        )
      }),
      it("returns an error with the line number for a line without =", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/missing_equals.env")

        // Assert
        result
        |> should
        |> be_equal(Error(MissingEquals("test/fixtures/missing_equals.env", 2)))
        |> or_fail_with("load_dotenv_from should report line 2")
      }),
      it("sets no variable when a line is not valid", fn() {
        // Arrange
        envoy.unset(good_name)
        use _ <- result.try(
          expect_load_error(loader.load_dotenv_from(
            "test/fixtures/missing_equals.env",
          )),
        )

        // Act
        let result = envoy.get(good_name)

        // Assert
        result
        |> should
        |> be_equal(Error(Nil))
        |> or_fail_with("load_dotenv_from should set nothing from a bad file")
      }),
      it("returns an error for a quote that is not closed", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/unclosed_quote.env")

        // Assert
        result
        |> should
        |> be_equal(
          Error(QuoteNotClosed(
            "test/fixtures/unclosed_quote.env",
            1,
            DoubleQuote,
          )),
        )
        |> or_fail_with("load_dotenv_from should report the open quote")
      }),
    ]),
    group("which value wins", [
      it("load_dotenv_from keeps a variable that is already set", fn() {
        // Arrange
        envoy.set(variable, "from the environment")
        use _ <- result.try(described(loader.load_dotenv_from(precedence_path)))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the environment"))
        |> or_fail_with("load_dotenv_from should not replace a set variable")
      }),
      it("load_dotenv_from keeps a variable that is set to empty", fn() {
        // Arrange
        envoy.set(variable, "")
        use _ <- result.try(described(loader.load_dotenv_from(precedence_path)))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok(""))
        |> or_fail_with("an empty variable is set, so the file should not win")
      }),
      it("load_dotenv_from sets a variable that is not set", fn() {
        // Arrange
        envoy.unset(variable)
        use _ <- result.try(described(loader.load_dotenv_from(precedence_path)))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the file"))
        |> or_fail_with(
          "load_dotenv_from should set a variable that is not set",
        )
      }),
      it("load_dotenv_from uses the last line for a repeated name", fn() {
        // Arrange
        envoy.unset(repeated)
        use _ <- result.try(described(loader.load_dotenv_from(precedence_path)))

        // Act
        let result = envoy.get(repeated)

        // Assert
        result
        |> should
        |> be_equal(Ok("second"))
        |> or_fail_with("the last line for a name should win")
      }),
      it("load_dotenv keeps a variable that is already set", fn() {
        // Arrange
        envoy.set(variable, "from the environment")
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_VALUE=from default\n")
          |> result.map_error(file.error_to_string),
        )
        use _ <- result.try(described(loader.load_dotenv()))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the environment"))
        |> or_fail_with("load_dotenv should not replace a set variable")
      }),
    ]),
    group("byte order mark", [
      it("the fixture starts with the bytes EF BB BF", fn() {
        // Act
        let result =
          file.read(byte_order_mark_path)
          |> result.map(string.starts_with(_, "\u{FEFF}"))

        // Assert
        result
        |> should
        |> be_equal(Ok(True))
        |> or_fail_with("the fixture should start with a byte order mark")
      }),
      it("load_dotenv_from does not put the mark in the first name", fn() {
        // Arrange
        envoy.unset(variable)
        use _ <- result.try(
          described(loader.load_dotenv_from(byte_order_mark_path)),
        )

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("after the mark"))
        |> or_fail_with("the first variable should be set without the mark")
      }),
    ]),
    group("empty values", [
      it("get returns an empty value", fn() {
        // Arrange
        envoy.set(variable, "")

        // Act
        let result = loader.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok(""))
        |> or_fail_with("an optional setting can be empty")
      }),
      it("get_required rejects an empty value", fn() {
        // Arrange
        envoy.set(variable, "")

        // Act
        let result = loader.get_required(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(Empty("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get_required should reject an empty value")
      }),
      it("get_required_int rejects an empty value", fn() {
        // Arrange
        envoy.set(variable, "")

        // Act
        let result = loader.get_required_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(Empty("DREAM_CONFIG_TEST_VALUE")))
        |> or_fail_with("get_required_int should reject an empty value")
      }),
    ]),
    group("load_dotenv_override_from", [
      it("replaces a variable that is already set", fn() {
        // Arrange
        envoy.set(variable, "from the environment")
        use _ <- result.try(
          described(loader.load_dotenv_override_from(precedence_path)),
        )

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the file"))
        |> or_fail_with("the file should win")
      }),
      it("replaces a variable that is set to empty", fn() {
        // Arrange
        envoy.set(variable, "")
        use _ <- result.try(
          described(loader.load_dotenv_override_from(precedence_path)),
        )

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the file"))
        |> or_fail_with("the file should win over an empty value")
      }),
      it("sets a variable that is not set", fn() {
        // Arrange
        envoy.unset(variable)
        use _ <- result.try(
          described(loader.load_dotenv_override_from(precedence_path)),
        )

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from the file"))
        |> or_fail_with("the file should set the variable")
      }),
      it("uses the last line for a repeated name", fn() {
        // Arrange
        envoy.set(repeated, "from the environment")
        use _ <- result.try(
          described(loader.load_dotenv_override_from(precedence_path)),
        )

        // Act
        let result = envoy.get(repeated)

        // Assert
        result
        |> should
        |> be_equal(Ok("second"))
        |> or_fail_with("the last line for a name should win")
      }),
      it("returns an error when the file does not exist", fn() {
        // Act
        let result =
          loader.load_dotenv_override_from("test/fixtures/does_not_exist.env")

        // Assert
        result
        |> should
        |> be_equal(Error(FileNotFound("test/fixtures/does_not_exist.env")))
        |> or_fail_with(
          "load_dotenv_override_from should report a missing file",
        )
      }),
    ]),
    group("load_dotenv_override", [
      it("returns Ok(Nil) when there is no .env file", fn() {
        // Arrange
        use _ <- result.try(test_file.delete_if_present(default_path))

        // Act
        let result = loader.load_dotenv_override()

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with(
          "load_dotenv_override should accept a missing .env file",
        )
      }),
      it("replaces a variable that is already set", fn() {
        // Arrange
        envoy.set(variable, "from the environment")
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_VALUE=from default\n")
          |> result.map_error(file.error_to_string),
        )
        use _ <- result.try(described(loader.load_dotenv_override()))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from default"))
        |> or_fail_with("the .env file should win")
      }),
      it("returns an error with the line number for a malformed file", fn() {
        // Arrange
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_DEFAULT\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv_override()

        // Assert
        result
        |> should
        |> be_equal(Error(MissingEquals(".env", 1)))
        |> or_fail_with("load_dotenv_override should report line 1")
      }),
    ]),
    group("load errors", [
      it("returns EmptyName for a line with no name", fn() {
        // Arrange
        use _ <- result.try(
          file.write(bad_line_path, "OK=1\n=value\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv_from(bad_line_path)

        // Assert
        result
        |> should
        |> be_equal(Error(EmptyName(bad_line_path, 2)))
        |> or_fail_with("load_dotenv_from should report the empty name")
      }),
      it("returns QuoteNotClosed for a single quote", fn() {
        // Arrange
        use _ <- result.try(
          file.write(bad_line_path, "OK=1\nNAME='open\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv_from(bad_line_path)

        // Assert
        result
        |> should
        |> be_equal(Error(QuoteNotClosed(bad_line_path, 2, SingleQuote)))
        |> or_fail_with("load_dotenv_from should report the single quote")
      }),
      it("returns QuoteNotClosed for a backtick", fn() {
        // Arrange
        use _ <- result.try(
          file.write(bad_line_path, "NAME=`open\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv_from(bad_line_path)

        // Assert
        result
        |> should
        |> be_equal(Error(QuoteNotClosed(bad_line_path, 1, Backtick)))
        |> or_fail_with("load_dotenv_from should report the backtick")
      }),
      it("returns TextAfterClosingQuote for text after a quote", fn() {
        // Arrange
        use _ <- result.try(
          file.write(bad_line_path, "NAME=\"value\" more\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv_from(bad_line_path)

        // Assert
        result
        |> should
        |> be_equal(Error(TextAfterClosingQuote(bad_line_path, 1, DoubleQuote)))
        |> or_fail_with(
          "load_dotenv_from should report the text after the quote",
        )
      }),
    ]),
    group("describe", [
      it("describes NotSet('PORT')", fn() {
        // Act
        let result = loader.describe(NotSet("PORT"))

        // Assert
        result
        |> should
        |> be_equal("Required environment variable not set: PORT")
        |> or_fail_with("describe should give the text")
      }),
      it("describes NotAnInteger('PORT', 'eighty')", fn() {
        // Act
        let result = loader.describe(NotAnInteger("PORT", "eighty"))

        // Assert
        result
        |> should
        |> be_equal("Environment variable PORT must be an integer")
        |> or_fail_with("describe should give the text")
      }),
      it("describes Empty('DATABASE_URL')", fn() {
        // Act
        let result = loader.describe(Empty("DATABASE_URL"))

        // Assert
        result
        |> should
        |> be_equal("Required environment variable is empty: DATABASE_URL")
        |> or_fail_with("describe should give the text")
      }),
    ]),
    group("describe_load_error", [
      it("describes FileNotFound('.env')", fn() {
        // Act
        let result = loader.describe_load_error(FileNotFound(".env"))

        // Assert
        result
        |> should
        |> be_equal("Cannot load .env file at .env: the file does not exist")
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes FileNotReadable('.env', 'permission denied')", fn() {
        // Act
        let result =
          loader.describe_load_error(FileNotReadable(
            ".env",
            "permission denied",
          ))

        // Assert
        result
        |> should
        |> be_equal("Cannot load .env file at .env: permission denied")
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes FileNotUtf8('.env')", fn() {
        // Act
        let result = loader.describe_load_error(FileNotUtf8(".env"))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: the file is not valid UTF-8",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes MissingEquals('.env', 2)", fn() {
        // Act
        let result = loader.describe_load_error(MissingEquals(".env", 2))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 2: expected NAME=VALUE",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes EmptyName('.env', 2)", fn() {
        // Act
        let result = loader.describe_load_error(EmptyName(".env", 2))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 2: expected NAME=VALUE",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes QuoteNotClosed('.env', 1, DoubleQuote)", fn() {
        // Act
        let result =
          loader.describe_load_error(QuoteNotClosed(".env", 1, DoubleQuote))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 1: the double quote is not closed",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes QuoteNotClosed('.env', 1, SingleQuote)", fn() {
        // Act
        let result =
          loader.describe_load_error(QuoteNotClosed(".env", 1, SingleQuote))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 1: the single quote is not closed",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes QuoteNotClosed('.env', 1, Backtick)", fn() {
        // Act
        let result =
          loader.describe_load_error(QuoteNotClosed(".env", 1, Backtick))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 1: the backtick is not closed",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
      it("describes TextAfterClosingQuote('.env', 1, SingleQuote)", fn() {
        // Act
        let result =
          loader.describe_load_error(TextAfterClosingQuote(
            ".env",
            1,
            SingleQuote,
          ))

        // Assert
        result
        |> should
        |> be_equal(
          "Cannot load .env file at .env: line 1: unexpected text after the closing single quote",
        )
        |> or_fail_with("describe_load_error should give the text")
      }),
    ]),
    group("load_dotenv", [
      it("returns Ok(Nil) when there is no .env file", fn() {
        // Arrange
        use _ <- result.try(test_file.delete_if_present(default_path))

        // Act
        let result = loader.load_dotenv()

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_dotenv should accept a missing .env file")
      }),
      it("returns Ok(Nil) for a valid .env file", fn() {
        // Arrange
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_VALUE=from default\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv()

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_dotenv should load a valid .env file")
      }),
      it("sets the variables of a valid .env file", fn() {
        // Arrange
        envoy.unset(variable)
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_VALUE=from default\n")
          |> result.map_error(file.error_to_string),
        )
        use _ <- result.try(described(loader.load_dotenv()))

        // Act
        let result = envoy.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Ok("from default"))
        |> or_fail_with("load_dotenv should set the variable")
      }),
      it("returns an error with the line number for a malformed file", fn() {
        // Arrange
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_DEFAULT\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = loader.load_dotenv()

        // Assert
        result
        |> should
        |> be_equal(Error(MissingEquals(".env", 1)))
        |> or_fail_with("load_dotenv should report line 1")
      }),
      it("returns an error when the .env file cannot be read", fn() {
        // Arrange
        use _ <- result.try(
          file.write(default_path, "DREAM_CONFIG_TEST_VALUE=1\n")
          |> result.map_error(file.error_to_string),
        )
        use _ <- result.try(
          test_file.make_unreadable(default_path)
          |> result.replace_error("Cannot make the .env file unreadable"),
        )

        // Act
        let result = loader.load_dotenv()

        // Assert
        result
        |> should
        |> be_equal(Error(FileNotReadable(".env", "permission denied")))
        |> or_fail_with("load_dotenv should report a file it cannot read")
      }),
    ]),
  ])
}

fn described(loaded: Result(Nil, loader.LoadError)) -> Result(Nil, String) {
  loaded |> result.map_error(loader.describe_load_error)
}

fn expect_load_error(
  loaded: Result(Nil, loader.LoadError),
) -> Result(Nil, String) {
  case loaded {
    Ok(Nil) -> Error("The file should not load")
    Error(_) -> Ok(Nil)
  }
}
