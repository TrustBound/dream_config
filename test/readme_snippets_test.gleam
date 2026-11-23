//// Tests for the code blocks in this package's README.md.
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import gleam/option
import gleam/result
import snippets/readme_boolean_values
import snippets/readme_load_env_files
import snippets/readme_optional_values
import snippets/readme_quick_start.{Settings}
import snippets/readme_required_values.{AppConfig}

pub fn tests() -> TestSuite {
  describe("README snippets", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
      Ok(Nil)
    }),
    group("readme_quick_start.load_settings", [
      it("reads the required and optional values", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "8080")
        envoy.set("DEBUG", "true")
        envoy.unset("API_KEY")

        // Act
        let result = readme_quick_start.load_settings()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(Settings(
            database_url: "postgres://localhost/app",
            port: 8080,
            debug_mode: True,
            api_key: "default-key",
          )),
        )
        |> or_fail_with("load_settings should read every value")
      }),
      it("returns an error when PORT is not set", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.unset("PORT")

        // Act
        let result = readme_quick_start.load_settings()

        // Assert
        result
        |> should
        |> be_equal(Error("Required environment variable not set: PORT"))
        |> or_fail_with("load_settings should name PORT")
      }),
    ]),
    group("readme_load_env_files.load_env_files", [
      it("returns Ok(Nil) for a valid file", fn() {
        // Act
        let result =
          readme_load_env_files.load_env_files("test/fixtures/myapp.env")

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_env_files should load the file")
      }),
      it("sets the variables from the file", fn() {
        // Arrange
        envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
        use _ <- result.try(readme_load_env_files.load_env_files(
          "test/fixtures/myapp.env",
        ))

        // Act
        let result = envoy.get("DREAM_CONFIG_SNIPPET_GREETING")

        // Assert
        result
        |> should
        |> be_equal(Ok("hello from myapp.env"))
        |> or_fail_with("load_env_files should set the variable")
      }),
      it("returns an error when the file does not exist", fn() {
        // Act
        let result =
          readme_load_env_files.load_env_files(
            "test/fixtures/does_not_exist.env",
          )

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist",
        ))
        |> or_fail_with("load_env_files should report the missing file")
      }),
      it("returns an error when a line is not valid", fn() {
        // Act
        let result =
          readme_load_env_files.load_env_files(
            "test/fixtures/missing_equals.env",
          )

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE",
        ))
        |> or_fail_with("load_env_files should report line 2")
      }),
    ]),
    group("readme_required_values.load_config", [
      it("reads DATABASE_URL and PORT", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "8080")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(
          Ok(AppConfig(database_url: "postgres://localhost/app", port: 8080)),
        )
        |> or_fail_with("load_config should read both values")
      }),
      it("returns an error when DATABASE_URL is not set", fn() {
        // Arrange
        envoy.unset("DATABASE_URL")
        envoy.set("PORT", "8080")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(Error("Required environment variable not set: DATABASE_URL"))
        |> or_fail_with("load_config should name DATABASE_URL")
      }),
      it("returns an error when PORT is not an integer", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "eighty")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(Error("Environment variable PORT must be an integer"))
        |> or_fail_with("load_config should reject PORT=eighty")
      }),
    ]),
    group("readme_optional_values.read_optional_values", [
      it("reads the values that are set", fn() {
        // Arrange
        envoy.set("API_KEY", "example-api-key")
        envoy.set("PORT", "8080")

        // Act
        let result = readme_optional_values.read_optional_values()

        // Assert
        result
        |> should
        |> be_equal(#(option.Some("example-api-key"), 8080))
        |> or_fail_with("read_optional_values should read both values")
      }),
      it("uses the defaults when the values are not set", fn() {
        // Arrange
        envoy.unset("API_KEY")
        envoy.unset("PORT")

        // Act
        let result = readme_optional_values.read_optional_values()

        // Assert
        result
        |> should
        |> be_equal(#(option.None, 3000))
        |> or_fail_with("read_optional_values should use the defaults")
      }),
    ]),
    group("readme_boolean_values.log_level", [
      it("returns debug when DEBUG is yes", fn() {
        // Arrange
        envoy.set("DEBUG", "yes")

        // Act
        let result = readme_boolean_values.log_level()

        // Assert
        result
        |> should
        |> be_equal("debug")
        |> or_fail_with("log_level should be debug for yes")
      }),
      it("returns debug when DEBUG is tRUE", fn() {
        // Arrange
        envoy.set("DEBUG", "tRUE")

        // Act
        let result = readme_boolean_values.log_level()

        // Assert
        result
        |> should
        |> be_equal("debug")
        |> or_fail_with("log_level should be debug for tRUE")
      }),
      it("returns info when DEBUG is false", fn() {
        // Arrange
        envoy.set("DEBUG", "false")

        // Act
        let result = readme_boolean_values.log_level()

        // Assert
        result
        |> should
        |> be_equal("info")
        |> or_fail_with("log_level should be info for false")
      }),
      it("returns info when DEBUG is not set", fn() {
        // Arrange
        envoy.unset("DEBUG")

        // Act
        let result = readme_boolean_values.log_level()

        // Assert
        result
        |> should
        |> be_equal("info")
        |> or_fail_with("log_level should be info when DEBUG is not set")
      }),
    ]),
  ])
}
