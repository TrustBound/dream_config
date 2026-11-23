//// Tests for the code blocks in the doc comments of `dream_config/loader`.
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import gleam/option
import gleam/result
import snippets/doc_get
import snippets/doc_get_int
import snippets/doc_get_required
import snippets/doc_get_required_int
import snippets/doc_load_dotenv
import snippets/doc_load_dotenv_from

pub fn tests() -> TestSuite {
  describe("doc comment snippets", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("API_KEY")
      envoy.unset("PORT")
      envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
      Ok(Nil)
    }),
    group("doc_load_dotenv.database_url_at_startup", [
      it("returns DATABASE_URL", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")

        // Act
        let result = doc_load_dotenv.database_url_at_startup()

        // Assert
        result
        |> should
        |> be_equal(Ok("postgres://localhost/app"))
        |> or_fail_with("database_url_at_startup should return the value")
      }),
      it("returns an error when DATABASE_URL is not set", fn() {
        // Arrange
        envoy.unset("DATABASE_URL")

        // Act
        let result = doc_load_dotenv.database_url_at_startup()

        // Assert
        result
        |> should
        |> be_equal(Error("Required environment variable not set: DATABASE_URL"))
        |> or_fail_with("database_url_at_startup should name DATABASE_URL")
      }),
    ]),
    group("doc_load_dotenv_from.load_settings_file", [
      it("returns Ok(Nil) for a valid file", fn() {
        // Act
        let result =
          doc_load_dotenv_from.load_settings_file("test/fixtures/myapp.env")

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_settings_file should load the file")
      }),
      it("sets the variables from the file", fn() {
        // Arrange
        envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
        use _ <- result.try(doc_load_dotenv_from.load_settings_file(
          "test/fixtures/myapp.env",
        ))

        // Act
        let result = envoy.get("DREAM_CONFIG_SNIPPET_GREETING")

        // Assert
        result
        |> should
        |> be_equal(Ok("hello from myapp.env"))
        |> or_fail_with("load_settings_file should set the variable")
      }),
      it("returns an error for a missing file", fn() {
        // Act
        let result =
          doc_load_dotenv_from.load_settings_file("test/fixtures/none.env")

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/none.env: the file does not exist",
        ))
        |> or_fail_with("load_settings_file should report the missing file")
      }),
    ]),
    group("doc_get_required.database_url", [
      it("returns DATABASE_URL", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://localhost/app")

        // Act
        let result = doc_get_required.database_url()

        // Assert
        result
        |> should
        |> be_equal(Ok("postgres://localhost/app"))
        |> or_fail_with("database_url should return the value")
      }),
      it("returns an error when DATABASE_URL is not set", fn() {
        // Arrange
        envoy.unset("DATABASE_URL")

        // Act
        let result = doc_get_required.database_url()

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot start the application: Required environment variable not set: DATABASE_URL",
        ))
        |> or_fail_with("database_url should add the startup message")
      }),
    ]),
    group("doc_get.api_key", [
      it("returns Some when API_KEY is set", fn() {
        // Arrange
        envoy.set("API_KEY", "example-api-key")

        // Act
        let result = doc_get.api_key()

        // Assert
        result
        |> should
        |> be_equal(option.Some("example-api-key"))
        |> or_fail_with("api_key should return Some")
      }),
      it("returns None when API_KEY is not set", fn() {
        // Arrange
        envoy.unset("API_KEY")

        // Act
        let result = doc_get.api_key()

        // Assert
        result
        |> should
        |> be_equal(option.None)
        |> or_fail_with("api_key should return None")
      }),
    ]),
    group("doc_get_int.server_port", [
      it("returns PORT", fn() {
        // Arrange
        envoy.set("PORT", "8080")

        // Act
        let result = doc_get_int.server_port()

        // Assert
        result
        |> should
        |> be_equal(8080)
        |> or_fail_with("server_port should return 8080")
      }),
      it("returns 3000 when PORT is not an integer", fn() {
        // Arrange
        envoy.set("PORT", "eighty")

        // Act
        let result = doc_get_int.server_port()

        // Assert
        result
        |> should
        |> be_equal(3000)
        |> or_fail_with("server_port should use the default")
      }),
    ]),
    group("doc_get_required_int.listen_address", [
      it("uses PORT", fn() {
        // Arrange
        envoy.set("PORT", "8080")

        // Act
        let result = doc_get_required_int.listen_address()

        // Assert
        result
        |> should
        |> be_equal(Ok("0.0.0.0:8080"))
        |> or_fail_with("listen_address should use the port")
      }),
      it("returns an error when PORT is not an integer", fn() {
        // Arrange
        envoy.set("PORT", "eighty")

        // Act
        let result = doc_get_required_int.listen_address()

        // Assert
        result
        |> should
        |> be_equal(Error("Environment variable PORT must be an integer"))
        |> or_fail_with("listen_address should reject PORT=eighty")
      }),
    ]),
  ])
}
