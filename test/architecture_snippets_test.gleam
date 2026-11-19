//// Tests for the dream_config snippet in Dream's architecture reference
//// (docs/reference/architecture.md in the dream repository).
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// them.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/architecture_config.{AppConfig}

pub fn tests() -> TestSuite(Nil) {
  describe("architecture_config.load_config", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      Ok(Nil)
    }),
    it("reads DATABASE_URL and PORT", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("PORT", "8080")

      // Act
      let result = architecture_config.load_config()

      // Assert
      result
      |> should
      |> be_equal(
        Ok(AppConfig(database_url: "postgres://localhost/app", port: 8080)),
      )
      |> or_fail_with("load_config should read both values")
    }),
    it("uses port 3000 when PORT is not set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.unset("PORT")

      // Act
      let result = architecture_config.load_config()

      // Assert
      result
      |> should
      |> be_equal(
        Ok(AppConfig(database_url: "postgres://localhost/app", port: 3000)),
      )
      |> or_fail_with("load_config should use port 3000")
    }),
    it("returns an error when DATABASE_URL is not set", fn() {
      // Arrange
      envoy.unset("DATABASE_URL")

      // Act
      let result = architecture_config.load_config()

      // Assert
      result
      |> should
      |> be_equal(Error("Required environment variable not set: DATABASE_URL"))
      |> or_fail_with("load_config should name DATABASE_URL")
    }),
  ])
}
