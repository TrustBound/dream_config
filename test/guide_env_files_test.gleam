//// Tests for the snippets and the facts of the .env guide
//// (docs/guides/env-files.md). `after_each` unsets every variable that a
//// test can set and deletes every file that a test can write.

import dream_config/loader as config
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import fixtures/test_file
import gleam/result
import snippets/doc_load_dotenv
import snippets/readme_load_env_files

const development_path = "test/fixtures/guide_development.env"

const secrets_path = "test/fixtures/guide_secrets.env"

const format_path = "test/fixtures/guide_format.env"

const unreadable_path = "build/guide_env_files_unreadable.env"

const byte_order_mark_path = "build/guide_env_files_byte_order_mark.env"

pub fn tests() -> TestSuite {
  describe("env files guide", [
    after_each(fn() {
      envoy.unset("DATABASE_URL")
      envoy.unset("PORT")
      envoy.unset("DEBUG")
      envoy.unset("API_KEY")
      envoy.unset("EXPORTED")
      envoy.unset("LOWER_NAME")
      envoy.unset("SPACED_VALUE")
      envoy.unset("PASSWORD")
      envoy.unset("QUOTED_PASSWORD")
      envoy.unset("URL")
      envoy.unset("EMPTY")
      envoy.unset("REFERENCE")
      envoy.unset("REPEATED")
      envoy.unset("DOUBLE_QUOTED")
      envoy.unset("SINGLE_QUOTED")
      envoy.unset("MULTILINE")
      envoy.unset("DREAM_CONFIG_TEST_GOOD_NAME")
      envoy.unset("DREAM_CONFIG_TEST_NOT_UTF8")
      envoy.unset("DREAM_CONFIG_TEST_GREETING")
      envoy.unset("DREAM_CONFIG_SNIPPET_GREETING")
      envoy.unset("\u{FEFF}DATABASE_URL")
      use _ <- result.try(test_file.delete_if_present(".env"))
      use _ <- result.try(test_file.delete_if_present(unreadable_path))
      test_file.delete_if_present(byte_order_mark_path)
    }),
    it("step 2: database_url_at_startup reads the .env file", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, ".env"))

      // Act
      let url = doc_load_dotenv.database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://localhost:5432/myapp_dev"))
      |> or_fail_with("The value should come from the .env file")
    }),
    it("step 2: with no .env file the value comes from the environment", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")

      // Act
      let url = doc_load_dotenv.database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://db.internal:5432/myapp"))
      |> or_fail_with("A missing .env file is not an error")
    }),
    it("step 2: a value in the .env file replaces a value that is set", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")
      use _ <- result.try(copy_file(development_path, ".env"))

      // Act
      let url = doc_load_dotenv.database_url_at_startup()

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://localhost:5432/myapp_dev"))
      |> or_fail_with("The .env file should win over the environment")
    }),
    it("step 3: load_env_files sets the variables of the second file", fn() {
      // Arrange
      use _ <- result.try(readme_load_env_files.load_env_files(secrets_path))

      // Act
      let key = config.get("API_KEY")

      // Assert
      key
      |> should
      |> be_equal(Ok("secret-from-the-platform"))
      |> or_fail_with("API_KEY should come from the secrets file")
    }),
    it("step 3: the second file wins over .env", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, ".env"))
      use _ <- result.try(readme_load_env_files.load_env_files(secrets_path))

      // Act
      let url = config.get("DATABASE_URL")

      // Assert
      url
      |> should
      |> be_equal(Ok("postgres://db.internal:5432/myapp"))
      |> or_fail_with("The file loaded last should win")
    }),
    it("errors: the file does not exist", fn() {
      // Act
      let loaded =
        readme_load_env_files.load_env_files("test/fixtures/does_not_exist.env")

      // Assert
      loaded
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist",
      ))
      |> or_fail_with("load_env_files should give the path and the reason")
    }),
    it("errors: a line has no =", fn() {
      // Act
      let loaded =
        readme_load_env_files.load_env_files("test/fixtures/missing_equals.env")

      // Assert
      loaded
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE",
      ))
      |> or_fail_with("load_env_files should give the path and the reason")
    }),
    it("errors: a quote is not closed", fn() {
      // Act
      let loaded =
        readme_load_env_files.load_env_files("test/fixtures/unclosed_quote.env")

      // Assert
      loaded
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/unclosed_quote.env: line 1: the double quote is not closed",
      ))
      |> or_fail_with("load_env_files should give the path and the reason")
    }),
    it("errors: the file is not UTF-8", fn() {
      // Act
      let loaded =
        readme_load_env_files.load_env_files("test/fixtures/not_utf8.env")

      // Assert
      loaded
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/not_utf8.env: the file is not valid UTF-8",
      ))
      |> or_fail_with("load_env_files should give the path and the reason")
    }),
    it("errors: the file cannot be read", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, unreadable_path))
      use _ <- result.try(
        test_file.make_unreadable(unreadable_path)
        |> result.replace_error("Cannot change the permissions"),
      )

      // Act
      let loaded = readme_load_env_files.load_env_files(unreadable_path)

      // Assert
      loaded
      |> should
      |> be_equal(Error(
        "Cannot load .env file at build/guide_env_files_unreadable.env: permission denied",
      ))
      |> or_fail_with("load_env_files should give the path and the reason")
    }),
    it("format: export before a name has no effect", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("EXPORTED")

      // Assert
      value
      |> should
      |> be_equal(Ok("yes"))
      |> or_fail_with("EXPORTED should be Ok('yes')")
    }),
    it("format: a lower-case name is changed to upper case", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("LOWER_NAME")

      // Assert
      value
      |> should
      |> be_equal(Ok("abc"))
      |> or_fail_with("LOWER_NAME should be Ok('abc')")
    }),
    it("format: the lower-case name is not set", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("lower_name")

      // Assert
      value
      |> should
      |> be_equal(Error(Nil))
      |> or_fail_with("lower_name should be Error(Nil)")
    }),
    it("format: spaces around an unquoted value are trimmed", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("SPACED_VALUE")

      // Assert
      value
      |> should
      |> be_equal(Ok("two words"))
      |> or_fail_with("SPACED_VALUE should be Ok('two words')")
    }),
    it("format: a # ends an unquoted value", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("PASSWORD")

      // Assert
      value
      |> should
      |> be_equal(Ok("abc"))
      |> or_fail_with("PASSWORD should be Ok('abc')")
    }),
    it("format: a # in quotes is part of the value", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("QUOTED_PASSWORD")

      // Assert
      value
      |> should
      |> be_equal(Ok("abc#def"))
      |> or_fail_with("QUOTED_PASSWORD should be Ok('abc#def')")
    }),
    it("format: the value starts after the first =", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("URL")

      // Assert
      value
      |> should
      |> be_equal(Ok("postgres://user:secret@db/app?sslmode=require"))
      |> or_fail_with(
        "URL should be Ok('postgres://user:secret@db/app?sslmode=require')",
      )
    }),
    it("format: an empty value is set as an empty string", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("EMPTY")

      // Assert
      value
      |> should
      |> be_equal(Ok(""))
      |> or_fail_with("EMPTY should be Ok('')")
    }),
    it("format: a reference to another variable is not expanded", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("REFERENCE")

      // Assert
      value
      |> should
      |> be_equal(Ok("${URL}"))
      |> or_fail_with("REFERENCE should be Ok('${URL}')")
    }),
    it("format: the last line for a name wins", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("REPEATED")

      // Assert
      value
      |> should
      |> be_equal(Ok("second"))
      |> or_fail_with("REPEATED should be Ok('second')")
    }),
    it("format: \\n in double quotes is a line break", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("DOUBLE_QUOTED")

      // Assert
      value
      |> should
      |> be_equal(Ok("one\ntwo"))
      |> or_fail_with("DOUBLE_QUOTED should be Ok('one\ntwo')")
    }),
    it("format: \\n in single quotes stays as written", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("SINGLE_QUOTED")

      // Assert
      value
      |> should
      |> be_equal(Ok("one\\ntwo"))
      |> or_fail_with("SINGLE_QUOTED should be Ok('one\\ntwo')")
    }),
    it("format: a quoted value can hold line breaks", fn() {
      // Arrange
      use _ <- result.try(config.load_dotenv_from(format_path))

      // Act
      let value = config.get("MULTILINE")

      // Assert
      value
      |> should
      |> be_equal(Ok("first line\nsecond line"))
      |> or_fail_with("MULTILINE should be Ok('first line\nsecond line')")
    }),
    it("pitfall: a byte order mark hides the first name", fn() {
      // Arrange
      use _ <- result.try(
        file.write(
          byte_order_mark_path,
          "\u{FEFF}DATABASE_URL=postgres://localhost/app\n",
        )
        |> result.map_error(file.error_to_string),
      )
      use _ <- result.try(config.load_dotenv_from(byte_order_mark_path))

      // Act
      let url = config.get("DATABASE_URL")

      // Assert
      url
      |> should
      |> be_equal(Error(Nil))
      |> or_fail_with("The mark becomes part of the first name today")
    }),
  ])
}

fn copy_file(from: String, to: String) -> Result(Nil, String) {
  use text <- result.try(
    file.read(from) |> result.map_error(file.error_to_string),
  )
  file.write(to, text) |> result.map_error(file.error_to_string)
}
