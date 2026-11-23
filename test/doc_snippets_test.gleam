//// Tests for the code blocks in the doc comments of `dream_config/loader`.
////
//// Each test sets the environment variables it needs. `after_each` unsets
//// every variable that a test can set and deletes the `.env` file that a
//// test can write.

import dream_config/loader.{FileNotFound, NotAnInteger}
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, group, it}
import envoy
import fixtures/test_file
import gleam/option
import gleam/result
import snippets/doc_describe
import snippets/doc_describe_load_error
import snippets/doc_get
import snippets/doc_get_required
import snippets/doc_get_required_int
import snippets/doc_load_dotenv
import snippets/doc_load_dotenv_from
import snippets/doc_load_dotenv_override
import snippets/doc_load_dotenv_override_from

pub fn tests() -> TestSuite {
  describe("doc comment snippets", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("API_KEY")
      envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
      test_file.delete_if_present(".env")
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
        |> or_fail_with("database_url_at_startup should read DATABASE_URL")
      }),
      it("returns the text of the error when DATABASE_URL is not set", fn() {
        // Act
        let result = doc_load_dotenv.database_url_at_startup()

        // Assert
        result
        |> should
        |> be_equal(Error("Required environment variable not set: DATABASE_URL"))
        |> or_fail_with("database_url_at_startup should name DATABASE_URL")
      }),
    ]),
    group("doc_load_dotenv_override.database_url_from_file", [
      it("returns the value of the .env file over the environment", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")
        use _ <- result.try(
          file.write(
            ".env",
            "DATABASE_URL=postgres://localhost:5432/myapp_dev\n",
          )
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = doc_load_dotenv_override.database_url_from_file()

        // Assert
        result
        |> should
        |> be_equal(Ok("postgres://localhost:5432/myapp_dev"))
        |> or_fail_with("the .env file should win")
      }),
      it("returns the text of the error for a malformed .env file", fn() {
        // Arrange
        use _ <- result.try(
          file.write(".env", "DATABASE_URL\n")
          |> result.map_error(file.error_to_string),
        )

        // Act
        let result = doc_load_dotenv_override.database_url_from_file()

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at .env: line 1: expected NAME=VALUE",
        ))
        |> or_fail_with("database_url_from_file should give the line")
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
      it("returns FileNotFound for a missing file", fn() {
        // Act
        let result =
          doc_load_dotenv_from.load_settings_file(
            "test/fixtures/does_not_exist.env",
          )

        // Assert
        result
        |> should
        |> be_equal(Error(FileNotFound("test/fixtures/does_not_exist.env")))
        |> or_fail_with("load_settings_file should report a missing file")
      }),
    ]),
    group("doc_load_dotenv_override_from.load_profile", [
      it("replaces a variable that is set", fn() {
        // Arrange
        envoy.set("DREAM_CONFIG_SNIPPET_GREETING", "from the environment")
        use _ <- result.try(
          doc_load_dotenv_override_from.load_profile("test/fixtures/myapp.env")
          |> result.map_error(loader.describe_load_error),
        )

        // Act
        let result = envoy.get("DREAM_CONFIG_SNIPPET_GREETING")

        // Assert
        result
        |> should
        |> be_equal(Ok("hello from myapp.env"))
        |> or_fail_with("the file should win")
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
        |> or_fail_with("database_url should read DATABASE_URL")
      }),
      it("returns a message when DATABASE_URL is not set", fn() {
        // Act
        let result = doc_get_required.database_url()

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot start the application: Required environment variable not set: DATABASE_URL",
        ))
        |> or_fail_with("database_url should name DATABASE_URL")
      }),
      it("returns a message when DATABASE_URL is empty", fn() {
        // Arrange
        envoy.set("DATABASE_URL", "")

        // Act
        let result = doc_get_required.database_url()

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot start the application: Required environment variable is empty: DATABASE_URL",
        ))
        |> or_fail_with("database_url should reject an empty value")
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
        |> or_fail_with("api_key should read API_KEY")
      }),
      it("returns None when API_KEY is not set", fn() {
        // Act
        let result = doc_get.api_key()

        // Assert
        result
        |> should
        |> be_equal(option.None)
        |> or_fail_with("api_key should be None")
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
        |> or_fail_with("listen_address should use PORT")
      }),
      it("returns NotAnInteger when PORT is not an integer", fn() {
        // Arrange
        envoy.set("PORT", "eighty")

        // Act
        let result = doc_get_required_int.listen_address()

        // Assert
        result
        |> should
        |> be_equal(Error(NotAnInteger("PORT", "eighty")))
        |> or_fail_with("listen_address should reject eighty")
      }),
    ]),
    group("doc_describe.port_problem", [
      it("describes a PORT that is not an integer", fn() {
        // Arrange
        envoy.set("PORT", "eighty")

        // Act
        let result = doc_describe.port_problem()

        // Assert
        result
        |> should
        |> be_equal("Environment variable PORT must be an integer")
        |> or_fail_with("port_problem should describe the error")
      }),
      it("says that a valid PORT is valid", fn() {
        // Arrange
        envoy.set("PORT", "8080")

        // Act
        let result = doc_describe.port_problem()

        // Assert
        result
        |> should
        |> be_equal("PORT is valid")
        |> or_fail_with("port_problem should accept 8080")
      }),
    ]),
    group("doc_describe_load_error.load_or_explain", [
      it("explains a line that is not valid", fn() {
        // Act
        let result =
          doc_describe_load_error.load_or_explain(
            "test/fixtures/missing_equals.env",
          )

        // Assert
        result
        |> should
        |> be_equal(Error(
          "Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE",
        ))
        |> or_fail_with("load_or_explain should give the path and the line")
      }),
      it("returns Ok(Nil) for a valid file", fn() {
        // Act
        let result =
          doc_describe_load_error.load_or_explain("test/fixtures/myapp.env")

        // Assert
        result
        |> should
        |> be_equal(Ok(Nil))
        |> or_fail_with("load_or_explain should load the file")
      }),
    ]),
  ])
}
