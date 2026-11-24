//// Guide: Getting started, test your code
////
//// Tests load_settings by setting the environment variables it reads.

import dream_config/loader.{NotSet}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/readme_quick_start.{Settings, load_settings}

pub fn tests() -> TestSuite {
  describe("load_settings", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      Ok(Nil)
    }),
    it("reads every setting from the environment", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/test")
      envoy.set("PORT", "4000")
      envoy.set("DEBUG", "yes")
      envoy.set("API_KEY", "test-key")

      // Act
      let settings = load_settings()

      // Assert
      settings
      |> should
      |> be_equal(
        Ok(Settings(
          database_url: "postgres://localhost/test",
          port: 4000,
          debug_mode: True,
          api_key: "test-key",
        )),
      )
      |> or_fail_with("Expected the settings from the environment")
    }),
    it("names the setting that is missing", fn() {
      // Arrange
      envoy.set("PORT", "4000")

      // Act
      let settings = load_settings()

      // Assert
      settings
      |> should
      |> be_equal(Error(NotSet("DATABASE_URL")))
      |> or_fail_with("Expected an error that names DATABASE_URL")
    }),
  ])
}
