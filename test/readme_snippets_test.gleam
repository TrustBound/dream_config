//// Tests for the snippets of the README (and of the getting started guide,
//// which shows the same snippets).
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set.

import dream_config/loader.{Empty, NotAnInteger, NotSet}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import snippets/readme_boolean_values
import snippets/readme_quick_start.{Settings}
import snippets/readme_required_values.{AppConfig}

pub fn tests() -> TestSuite {
  describe("README snippets", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      Ok(Nil)
    }),
    group("readme_quick_start.load_settings", [
      it("reads the required and optional values", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "8080")
        envoy.set("DEBUG", "true")

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
      it("returns NotSet when PORT is not set", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")

        // Act
        let result = readme_quick_start.load_settings()

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("PORT")))
        |> or_fail_with("load_settings should name PORT")
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
      it("returns NotSet when DATABASE_URL is not set", fn() {
        // Arrange
        envoy.set("PORT", "8080")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("DATABASE_URL")))
        |> or_fail_with("load_config should name DATABASE_URL")
      }),
      it("returns Empty when DATABASE_URL is empty", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "")
        envoy.set("PORT", "8080")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(Error(Empty("DATABASE_URL")))
        |> or_fail_with("load_config should reject an empty DATABASE_URL")
      }),
      it("returns NotAnInteger when PORT is not an integer", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "eighty")

        // Act
        let result = readme_required_values.load_config()

        // Assert
        result
        |> should
        |> be_equal(Error(NotAnInteger("PORT", "eighty")))
        |> or_fail_with("load_config should reject eighty")
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
        |> or_fail_with("log_level should read yes as True")
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
        |> or_fail_with("log_level should read tRUE as True")
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
        |> or_fail_with("log_level should read false as False")
      }),
      it("returns info when DEBUG is not set", fn() {
        // Act
        let result = readme_boolean_values.log_level()

        // Assert
        result
        |> should
        |> be_equal("info")
        |> or_fail_with("log_level should read a missing DEBUG as False")
      }),
    ]),
  ])
}
