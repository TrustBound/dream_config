//// Tests for the snippets of the getting started guide
//// (docs/guides/getting-started.md). Each test sets the environment
//// variables it needs and asserts the exact value or output that the guide
//// shows. `after_each` unsets every variable that a test can set and deletes
//// the `.env` file that a test can write.

import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import fixtures/child_process
import fixtures/output_file
import fixtures/test_file
import gleam/result
import snippets/guide_getting_started_main

const main_module = "snippets@guide_getting_started_main"

pub fn tests() -> TestSuite {
  describe("getting started guide", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      test_file.delete_if_present(".env")
    }),
    it("step 3: start returns the message of the running app", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("PORT", "8080")

      // Act
      let started = guide_getting_started_main.start()

      // Assert
      started
      |> should
      |> be_equal(Ok("Listening on port 8080"))
      |> or_fail_with("start should use the port from PORT")
    }),
    it("step 3: main prints the message and exits with status 0", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("PORT", "8080")
      use shown <- result.try(output_file.read(
        "guide_getting_started_step_3_environment",
      ))

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(0, shown))
      |> or_fail_with("main should print the message and return")
    }),
    it("step 3: main names a missing setting and exits with status 1", fn() {
      // Arrange
      envoy.set("PORT", "8080")
      use shown <- result.try(output_file.read(
        "guide_getting_started_missing_setting",
      ))

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(1, shown))
      |> or_fail_with("main should stop with the reason")
    }),
    it("step 3: main names a wrong setting and exits with status 1", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("PORT", "eighty")
      use shown <- result.try(output_file.read(
        "guide_getting_started_wrong_setting",
      ))

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(1, shown))
      |> or_fail_with("main should stop with the reason")
    }),
    it("step 3: main names an empty setting and exits with status 1", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "")
      envoy.set("PORT", "8080")
      use shown <- result.try(output_file.read(
        "guide_getting_started_empty_setting",
      ))

      // Act
      let result = child_process.run_main(main_module)

      // Assert
      result
      |> should
      |> be_equal(#(1, shown))
      |> or_fail_with("main should stop with the reason")
    }),
    it("step 3: main names a bad .env line and exits with status 1", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL\n")
        |> result.map_error(file.error_to_string),
      )
      use shown <- result.try(output_file.read(
        "guide_getting_started_bad_env_line",
      ))

      // Act
      let result = child_process.run_main(main_module)

      // Assert
      result
      |> should
      |> be_equal(#(1, shown))
      |> or_fail_with("main should stop with the reason")
    }),
    it("step 3: main reads the .env file", fn() {
      // Arrange
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/app\nPORT=4000\n")
        |> result.map_error(file.error_to_string),
      )
      use shown <- result.try(output_file.read(
        "guide_getting_started_step_3_env_file",
      ))

      // Act
      let result = child_process.run_main(main_module)

      // Assert
      result
      |> should
      |> be_equal(#(0, shown))
      |> or_fail_with("main should read the .env file")
    }),
    it("step 3: a PORT that is set wins over the .env file", fn() {
      // Arrange
      envoy.set("PORT", "8080")
      use _ <- result.try(
        file.write(".env", "DATABASE_URL=postgres://localhost/app\nPORT=4000\n")
        |> result.map_error(file.error_to_string),
      )
      use shown <- result.try(output_file.read(
        "guide_getting_started_step_3_shell_wins",
      ))

      // Act
      let result = child_process.run_main(main_module)

      // Assert
      result
      |> should
      |> be_equal(#(0, shown))
      |> or_fail_with("the environment should win")
    }),
  ])
}
