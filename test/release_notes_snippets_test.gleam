//// Tests for the snippets of the 2.0.0 release notes
//// (releases/release-2.0.0.md).
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set.

import dream_config/loader.{NotSet}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import snippets/release_migration_errors
import snippets/release_migration_may_be_empty

pub fn tests() -> TestSuite {
  describe("release notes snippets", [
    after_each(fn() {
      envoy.unset("PORT")
      envoy.unset("LOG_PREFIX")
      Ok(Nil)
    }),
    group("release_migration_errors.port_hint", [
      it("accepts a valid PORT", fn() {
        // Arrange
        envoy.set("PORT", "8080")

        // Act
        let result = release_migration_errors.port_hint()

        // Assert
        result
        |> should
        |> be_equal("PORT is valid")
        |> or_fail_with("port_hint should accept 8080")
      }),
      it("matches NotSet", fn() {
        // Act
        let result = release_migration_errors.port_hint()

        // Assert
        result
        |> should
        |> be_equal("Set PORT, for example PORT=8080")
        |> or_fail_with("port_hint should match NotSet")
      }),
      it("matches Empty", fn() {
        // Arrange
        envoy.set("PORT", "")

        // Act
        let result = release_migration_errors.port_hint()

        // Assert
        result
        |> should
        |> be_equal("PORT is empty")
        |> or_fail_with("port_hint should match Empty")
      }),
      it("matches NotAnInteger", fn() {
        // Arrange
        envoy.set("PORT", "eighty")

        // Act
        let result = release_migration_errors.port_hint()

        // Assert
        result
        |> should
        |> be_equal("PORT is not a number: eighty")
        |> or_fail_with("port_hint should match NotAnInteger")
      }),
    ]),
    group("release_migration_may_be_empty.log_prefix", [
      it("returns an empty LOG_PREFIX", fn() {
        // Arrange
        envoy.set("LOG_PREFIX", "")

        // Act
        let result = release_migration_may_be_empty.log_prefix()

        // Assert
        result
        |> should
        |> be_equal(Ok(""))
        |> or_fail_with("log_prefix should accept an empty value")
      }),
      it("returns NotSet when LOG_PREFIX is not set", fn() {
        // Act
        let result = release_migration_may_be_empty.log_prefix()

        // Assert
        result
        |> should
        |> be_equal(Error(NotSet("LOG_PREFIX")))
        |> or_fail_with("log_prefix should report NotSet")
      }),
    ]),
  ])
}
