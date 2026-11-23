//// Tests for the snippets and the facts of the guide on optional settings,
//// numbers and flags (docs/guides/typed-values.md). `after_each` unsets
//// every variable that a test can set.

import dream_config/loader.{NotAnInteger} as config
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import gleam/option
import gleam/result
import snippets/doc_get
import snippets/guide_typed_values_pool_size
import snippets/guide_typed_values_port

pub fn tests() -> TestSuite {
  describe("typed values guide", [
    after_each(fn() {
      envoy.unset("PORT")
      envoy.unset("API_KEY")
      envoy.unset("DEBUG")
      envoy.unset("POOL_SIZE")
      Ok(Nil)
    }),
    it("step 1: port rejects a PORT that is not a number", fn() {
      // Arrange
      envoy.set("PORT", "eighty")

      // Act
      let result = guide_typed_values_port.port()

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "eighty")))
      |> or_fail_with("port should stop on eighty")
    }),
    it("step 1: port rejects an empty PORT", fn() {
      // Arrange
      envoy.set("PORT", "")

      // Act
      let result = guide_typed_values_port.port()

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "")))
      |> or_fail_with("port should stop on an empty value")
    }),
    it("step 1: describe gives the text for a PORT that is not a number", fn() {
      // Arrange
      envoy.set("PORT", "eighty")

      // Act
      let result =
        guide_typed_values_port.port() |> result.map_error(config.describe)

      // Assert
      result
      |> should
      |> be_equal(Error("Environment variable PORT must be an integer"))
      |> or_fail_with("describe should name PORT")
    }),
    it("step 1: result.unwrap hides a PORT that is not a number", fn() {
      // Arrange
      envoy.set("PORT", "eighty")

      // Act
      let result = config.get_int("PORT") |> result.unwrap(3000)

      // Assert
      result
      |> should
      |> be_equal(3000)
      |> or_fail_with("unwrap should give the default")
    }),
    it("step 2: api_key reads API_KEY", fn() {
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
    it("step 2: api_key is None when API_KEY is not set", fn() {
      // Act
      let result = doc_get.api_key()

      // Assert
      result
      |> should
      |> be_equal(option.None)
      |> or_fail_with("api_key should be None")
    }),
    it("step 2: api_key keeps an empty API_KEY", fn() {
      // Arrange
      envoy.set("API_KEY", "")

      // Act
      let result = doc_get.api_key()

      // Assert
      result
      |> should
      |> be_equal(option.Some(""))
      |> or_fail_with("an optional value can be empty")
    }),
    it("step 3: get_bool reads true as True", fn() {
      // Arrange
      envoy.set("DEBUG", "true")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(True)
      |> or_fail_with("true should be True")
    }),
    it("step 3: get_bool reads TRUE as True", fn() {
      // Arrange
      envoy.set("DEBUG", "TRUE")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(True)
      |> or_fail_with("TRUE should be True")
    }),
    it("step 3: get_bool reads tRUE as True", fn() {
      // Arrange
      envoy.set("DEBUG", "tRUE")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(True)
      |> or_fail_with("tRUE should be True")
    }),
    it("step 3: get_bool reads Yes as True", fn() {
      // Arrange
      envoy.set("DEBUG", "Yes")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(True)
      |> or_fail_with("Yes should be True")
    }),
    it("step 3: get_bool reads 1 as True", fn() {
      // Arrange
      envoy.set("DEBUG", "1")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(True)
      |> or_fail_with("1 should be True")
    }),
    it("step 3: get_bool reads on as False", fn() {
      // Arrange
      envoy.set("DEBUG", "on")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("on should be False")
    }),
    it("step 3: get_bool reads y as False", fn() {
      // Arrange
      envoy.set("DEBUG", "y")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("y should be False")
    }),
    it("step 3: get_bool reads 0 as False", fn() {
      // Arrange
      envoy.set("DEBUG", "0")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("0 should be False")
    }),
    it("step 3: get_bool reads false as False", fn() {
      // Arrange
      envoy.set("DEBUG", "false")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("false should be False")
    }),
    it("step 3: get_bool reads  true as False", fn() {
      // Arrange
      envoy.set("DEBUG", " true")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("true should be False")
    }),
    it("step 3: get_bool reads ture as False", fn() {
      // Arrange
      envoy.set("DEBUG", "ture")

      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("ture should be False")
    }),
    it("step 3: get_bool reads a variable that is not set as False", fn() {
      // Act
      let result = config.get_bool("DEBUG")

      // Assert
      result
      |> should
      |> be_equal(False)
      |> or_fail_with("A missing flag should be False")
    }),
    it("step 4: pool_size with a number in the range", fn() {
      // Arrange
      envoy.set("POOL_SIZE", "20")

      // Act
      let result = guide_typed_values_pool_size.pool_size()

      // Assert
      result
      |> should
      |> be_equal(Ok(20))
      |> or_fail_with("pool_size should handle a number in the range")
    }),
    it("step 4: pool_size with a number below the range", fn() {
      // Arrange
      envoy.set("POOL_SIZE", "0")

      // Act
      let result = guide_typed_values_pool_size.pool_size()

      // Assert
      result
      |> should
      |> be_equal(Error("POOL_SIZE must be from 1 to 100, got 0"))
      |> or_fail_with("pool_size should handle a number below the range")
    }),
    it("step 4: pool_size with a value that is not a number", fn() {
      // Arrange
      envoy.set("POOL_SIZE", "twenty")

      // Act
      let result = guide_typed_values_pool_size.pool_size()

      // Assert
      result
      |> should
      |> be_equal(Error("Environment variable POOL_SIZE must be an integer"))
      |> or_fail_with("pool_size should handle a value that is not a number")
    }),
    it("step 4: pool_size when POOL_SIZE is not set", fn() {
      // Act
      let result = guide_typed_values_pool_size.pool_size()

      // Assert
      result
      |> should
      |> be_equal(Error("Required environment variable not set: POOL_SIZE"))
      |> or_fail_with("pool_size should name POOL_SIZE")
    }),
    it("step 4: pool_size when POOL_SIZE is empty", fn() {
      // Arrange
      envoy.set("POOL_SIZE", "")

      // Act
      let result = guide_typed_values_pool_size.pool_size()

      // Assert
      result
      |> should
      |> be_equal(Error("Required environment variable is empty: POOL_SIZE"))
      |> or_fail_with("pool_size should reject an empty value")
    }),
    it("numbers: get_int reads `8080` as Ok(8080)", fn() {
      // Arrange
      envoy.set("PORT", "8080")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Ok(8080))
      |> or_fail_with("get_int should read 8080 as Ok(8080)")
    }),
    it("numbers: get_int reads `+8080` as Ok(8080)", fn() {
      // Arrange
      envoy.set("PORT", "+8080")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Ok(8080))
      |> or_fail_with("get_int should read +8080 as Ok(8080)")
    }),
    it("numbers: get_int reads `08080` as Ok(8080)", fn() {
      // Arrange
      envoy.set("PORT", "08080")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Ok(8080))
      |> or_fail_with("get_int should read 08080 as Ok(8080)")
    }),
    it("numbers: get_int reads `-1` as Ok(-1)", fn() {
      // Arrange
      envoy.set("PORT", "-1")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Ok(-1))
      |> or_fail_with("get_int should read -1 as Ok(-1)")
    }),
    it("numbers: get_int reads ` 8080` as NotAnInteger", fn() {
      // Arrange
      envoy.set("PORT", " 8080")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", " 8080")))
      |> or_fail_with("get_int should read 8080 as NotAnInteger")
    }),
    it("numbers: get_int reads `8_080` as NotAnInteger", fn() {
      // Arrange
      envoy.set("PORT", "8_080")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "8_080")))
      |> or_fail_with("get_int should read 8_080 as NotAnInteger")
    }),
    it("numbers: get_int reads `0x1F` as NotAnInteger", fn() {
      // Arrange
      envoy.set("PORT", "0x1F")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "0x1F")))
      |> or_fail_with("get_int should read 0x1F as NotAnInteger")
    }),
    it("numbers: get_int reads `8080.0` as NotAnInteger", fn() {
      // Arrange
      envoy.set("PORT", "8080.0")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "8080.0")))
      |> or_fail_with("get_int should read 8080.0 as NotAnInteger")
    }),
    it("numbers: get_int reads `` as NotAnInteger", fn() {
      // Arrange
      envoy.set("PORT", "")

      // Act
      let result = config.get_int("PORT")

      // Assert
      result
      |> should
      |> be_equal(Error(NotAnInteger("PORT", "")))
      |> or_fail_with("get_int should read empty as NotAnInteger")
    }),
  ])
}
