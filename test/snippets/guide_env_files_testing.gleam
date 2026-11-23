//// Guide: Use a .env file in development, test your code
////
//// Tests code that loads .env by writing the file in the test.

import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import gleam/result
import snippets/doc_load_dotenv.{database_url_at_startup}

pub fn tests() -> TestSuite {
  describe("database_url_at_startup", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      file.delete(".env")
      |> result.map_error(file.error_to_string)
    }),
    it("reads DATABASE_URL from the .env file", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/test\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://localhost/test"))
      |> or_fail_with("Expected the value from the .env file")
    }),
    it("keeps a DATABASE_URL that is already set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://ci-database/test")
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/test\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://ci-database/test"))
      |> or_fail_with("Expected the value from the environment")
    }),
    it("stops at a line that is not valid", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL\n")
        |> result.map_error(file.error_to_string),
      )

      // Act
      let url = database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Error(
        "Cannot load .env file at .env: line 1: expected NAME=VALUE",
      ))
      |> or_fail_with("Expected the line number and the reason")
    }),
  ])
}
