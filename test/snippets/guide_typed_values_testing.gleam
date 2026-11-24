//// Guide: Optional settings, numbers and flags, test your code
////
//// Tests port for each case: not set, a number, and not a number.

import dream_config/loader.{NotAnInteger}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import snippets/guide_typed_values_port.{port}

pub fn tests() -> TestSuite {
  describe("port", [
    after_each(fn() {
      envoy.unset("PORT")
      Ok(Nil)
    }),
    it("uses 3000 when PORT is not set", fn() {
      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Ok(3000))
      |> or_fail_with("Expected the default port")
    }),
    it("reads PORT when it is a number", fn() {
      // Arrange
      envoy.set("PORT", "8080")

      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Ok(8080))
      |> or_fail_with("Expected the port from PORT")
    }),
    it("rejects a PORT that is not a number", fn() {
      // Arrange
      envoy.set("PORT", "80a")

      // Act
      let result = port()

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "80a")))
      |> or_fail_with("Expected an error, not the default")
    }),
  ])
}
