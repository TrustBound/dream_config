//// Tests for the snippets of the getting started guide
//// (docs/guides/getting-started.md). Each test sets the environment
//// variables it needs and asserts the exact value or output that the guide
//// shows. `after_each` unsets every variable that a test can set.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import fixtures/child_process
import snippets/guide_getting_started_main

const main_module = "snippets@guide_getting_started_main"

pub fn tests() -> TestSuite {
  describe("getting started guide", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      Ok(Nil)
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

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(0, "Listening on port 8080\n"))
      |> or_fail_with("main should print the message and return")
    }),
    it("step 3: main names a missing setting and exits with status 1", fn() {
      // Arrange
      envoy.set("PORT", "8080")

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(
        1,
        "Cannot start: Required environment variable not set: DATABASE_URL\n",
      ))
      |> or_fail_with("main should stop with the reason")
    }),
    it("step 3: main names a wrong setting and exits with status 1", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://localhost/app")
      envoy.set("PORT", "eighty")

      // Act
      let ran = child_process.run_main(main_module)

      // Assert
      ran
      |> should
      |> be_equal(#(
        1,
        "Cannot start: Environment variable PORT must be an integer\n",
      ))
      |> or_fail_with("main should stop with the reason")
    }),
  ])
}
