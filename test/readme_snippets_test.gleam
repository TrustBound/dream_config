//// Tests for the snippets of the README (and of the getting started guide,
//// which shows the same snippets).
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import fixtures/output_file
import gleam/result
import snippets/readme_boolean_values
import snippets/readme_quick_start
import snippets/readme_required_values

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
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_2_loaded",
        ))

        // Act
        let result = readme_quick_start.load_settings()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
        |> or_fail_with("load_settings should read every value")
      }),
      it("returns NotSet when PORT is not set", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_2_port_not_set",
        ))

        // Act
        let result = readme_quick_start.load_settings()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
        |> or_fail_with("load_settings should name PORT")
      }),
    ]),
    group("readme_required_values.load_config", [
      it("reads DATABASE_URL and PORT", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "8080")
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_1_loaded",
        ))

        // Act
        let result = readme_required_values.load_config()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
        |> or_fail_with("load_config should read both values")
      }),
      it("returns NotSet when DATABASE_URL is not set", fn() {
        // Arrange
        envoy.set("PORT", "8080")
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_1_not_set",
        ))

        // Act
        let result = readme_required_values.load_config()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
        |> or_fail_with("load_config should name DATABASE_URL")
      }),
      it("returns Empty when DATABASE_URL is empty", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "")
        envoy.set("PORT", "8080")
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_1_empty",
        ))

        // Act
        let result = readme_required_values.load_config()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
        |> or_fail_with("load_config should reject an empty DATABASE_URL")
      }),
      it("returns NotAnInteger when PORT is not an integer", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")
        envoy.set("PORT", "eighty")
        use shown <- result.try(output_file.read(
          "guide_getting_started_step_1_not_an_integer",
        ))

        // Act
        let result = readme_required_values.load_config()

        // Assert
        output_file.inspected(result)
        |> should
        |> be_equal(shown)
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
