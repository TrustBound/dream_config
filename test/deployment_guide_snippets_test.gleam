//// Tests for the config snippet in Dream's deployment guide
//// (docs/guides/deployment.md in the dream repository).
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// them.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/deployment_guide_config.{Config}

pub fn tests() -> TestSuite {
  describe("deployment_guide_config.load", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("SECRET_KEY")
      envoy.unset("PORT")
      Ok(Nil)
    }),
    it("returns the config when every variable is set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("SECRET_KEY", "example-secret-key")
      envoy.set("PORT", "8080")

      // Act
      let result = deployment_guide_config.load()

      // Assert
      result
      |> should
      |> be_equal(
        Ok(Config(
          database_url: "postgres://localhost/app",
          port: 8080,
          secret_key: "example-secret-key",
        )),
      )
      |> or_fail_with("load should read every value")
    }),
    it("uses port 3000 when PORT is not set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("SECRET_KEY", "example-secret-key")
      envoy.unset("PORT")

      // Act
      let result = deployment_guide_config.load()

      // Assert
      result
      |> should
      |> be_equal(
        Ok(Config(
          database_url: "postgres://localhost/app",
          port: 3000,
          secret_key: "example-secret-key",
        )),
      )
      |> or_fail_with("load should use port 3000")
    }),
    it("returns an error when PORT is not a number", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("SECRET_KEY", "example-secret-key")
      envoy.set("PORT", "eighty")

      // Act
      let result = deployment_guide_config.load()

      // Assert
      result
      |> should
      |> be_equal(Error("PORT must be a number, got: eighty"))
      |> or_fail_with("load should reject PORT=eighty")
    }),
    it("returns an error when DATABASE_URL is not set", fn() {
      // Arrange
      envoy.unset("DATABASE_URL")
      envoy.set("SECRET_KEY", "example-secret-key")
      envoy.set("PORT", "8080")

      // Act
      let result = deployment_guide_config.load()

      // Assert
      result
      |> should
      |> be_equal(Error("DATABASE_URL not set"))
      |> or_fail_with("load should name DATABASE_URL")
    }),
    it("returns an error when SECRET_KEY is not set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.unset("SECRET_KEY")
      envoy.set("PORT", "8080")

      // Act
      let result = deployment_guide_config.load()

      // Assert
      result
      |> should
      |> be_equal(Error("SECRET_KEY not set"))
      |> or_fail_with("load should name SECRET_KEY")
    }),
  ])
}
