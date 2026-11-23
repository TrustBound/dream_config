//// Tests for `dream_config/loader`.
////
//// The tests set the environment variables they read. `after_each` unsets
//// every variable that a test can set and deletes the files that a test can
//// write, so each test starts from the same state.

import dream_config/loader
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import fixtures/test_file
import gleam/list
import gleam/result

const variable = "DREAM_CONFIG_TEST_VALUE"

const greeting = "DREAM_CONFIG_SNIPPET_GREETING"

const good_name = "DREAM_CONFIG_TEST_GOOD_NAME"

const unreadable_path = "build/dream_config_unreadable_test.env"

const default_path = ".env"

pub fn tests() -> TestSuite {
  describe("dream_config/loader", [
    after_each(fn() {
      envoy.unset(variable)
      envoy.unset(greeting)
      envoy.unset(good_name)
      use _ <- result.try(test_file.delete_if_present(unreadable_path))
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
      it("returns Error(Nil) when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(Nil))
        |> or_fail_with("get should return Error(Nil) for a missing variable")
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
        |> be_equal(Error(
          "Required environment variable not set: DREAM_CONFIG_TEST_VALUE",
        ))
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
      it("returns Error(Nil) when the value is not an integer", fn() {
        // Arrange
        envoy.set(variable, "eighty")

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(Nil))
        |> or_fail_with("get_int should reject eighty")
      }),
      it("returns Error(Nil) when the variable is not set", fn() {
        // Arrange
        envoy.unset(variable)

        // Act
        let result = loader.get_int(variable)

        // Assert
        result
        |> should
        |> be_equal(Error(Nil))
        |> or_fail_with(
          "get_int should return Error(Nil) for a missing variable",
        )
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
          |> be_equal(Error(
            "Environment variable DREAM_CONFIG_TEST_VALUE must be an integer",
          ))
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
        |> be_equal(Error(
          "Required environment variable not set: DREAM_CONFIG_TEST_VALUE",
        ))
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
        use _ <- result.try(loader.load_dotenv_from("test/fixtures/myapp.env"))

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
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist",
        ))
        |> or_fail_with("load_dotenv_from should report a missing file")
      }),
      it("returns an error when the path is a directory", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures")

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures: illegal operation on a directory",
        ))
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
        |> be_equal(Error(
          "Cannot load .env file at build/dream_config_unreadable_test.env: permission denied",
        ))
        |> or_fail_with("load_dotenv_from should report a file it cannot read")
      }),
      it("returns an error when the file is not UTF-8", fn() {
        // Act
        let result = loader.load_dotenv_from("test/fixtures/not_utf8.env")

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/not_utf8.env: the file is not valid UTF-8",
        ))
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
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE",
        ))
        |> or_fail_with("load_dotenv_from should report line 2")
      }),
      it("sets no variable when a line is not valid", fn() {
        // Arrange
        envoy.unset(good_name)
        let _error = loader.load_dotenv_from("test/fixtures/missing_equals.env")

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
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/unclosed_quote.env: line 1: the double quote is not closed",
        ))
        |> or_fail_with("load_dotenv_from should report the open quote")
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
        use _ <- result.try(loader.load_dotenv())

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
        |> be_equal(Error(
          "Cannot load .env file at .env: line 1: expected NAME=VALUE",
        ))
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
        |> be_equal(Error("Cannot load .env file at .env: permission denied"))
        |> or_fail_with("load_dotenv should report a file it cannot read")
      }),
    ]),
  ])
}
