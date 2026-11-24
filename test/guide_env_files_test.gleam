//// Tests for the snippets and the facts of the .env guide
//// (docs/guides/env-files.md). `after_each` unsets every variable that a
//// test can set and deletes every file that a test can write.

import dream_config/loader.{
  DoubleQuote, FileNotFound, FileNotReadable, FileNotUtf8, MissingEquals, NotSet,
  QuoteNotClosed,
} as config
import dream_test/file
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{after_each, describe, it}
import envoy
import fixtures/output_file
import fixtures/test_file
import gleam/result
import snippets/doc_load_dotenv
import snippets/doc_load_dotenv_override
import snippets/readme_load_env_files

const development_path = "test/fixtures/guide_development.env"

const secrets_path = "test/fixtures/guide_secrets.env"

const format_path = "test/fixtures/guide_format.env"

const unreadable_path = "build/guide_env_files_unreadable.env"

const byte_order_mark_path = "test/fixtures/byte_order_mark.env"

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
      envoy.unset("DREAM_CONFIG_TEST_VALUE")
      use _ <- result.try(test_file.delete_if_present(".env"))
      test_file.delete_if_present(unreadable_path)
    }),
    it("step 2: database_url_at_startup reads the .env file", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, ".env"))
      use shown <- result.try(output_file.read(
        "guide_env_files_step_2_file_value",
      ))

      // Act
      let url = doc_load_dotenv.database_url_at_startup()

      // Assert
      output_file.inspected(url)
      |> should
      |> be_equal(shown)
      |> or_fail_with("The value should come from the .env file")
    }),
    it("step 2: with no .env file the value comes from the environment", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")
      use shown <- result.try(output_file.read("guide_env_files_step_2_no_file"))

      // Act
      let url = doc_load_dotenv.database_url_at_startup()

      // Assert
      output_file.inspected(url)
      |> should
      |> be_equal(shown)
      |> or_fail_with("A missing .env file is not an error")
    }),
    it("step 2: a variable that is set wins over the .env file", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")
      use _ <- result.try(copy_file(development_path, ".env"))
      use shown <- result.try(output_file.read(
        "guide_env_files_step_2_environment_wins",
      ))

      // Act
      let result = doc_load_dotenv.database_url_at_startup()

      // Assert
      output_file.inspected(result)
      |> should
      |> be_equal(shown)
      |> or_fail_with("The environment should win over the .env file")
    }),
    it("step 3: database_url_from_file lets the .env file win", fn() {
      // Arrange
      envoy.set("DATABASE_URL", "postgres://db.internal:5432/myapp")
      use _ <- result.try(copy_file(development_path, ".env"))
      use shown <- result.try(output_file.read(
        "guide_env_files_step_3_file_wins",
      ))

      // Act
      let result = doc_load_dotenv_override.database_url_from_file()

      // Assert
      output_file.inspected(result)
      |> should
      |> be_equal(shown)
      |> or_fail_with("The .env file should win with load_dotenv_override")
    }),
    it("step 4: load_env_files sets the variables of the secrets file", fn() {
      // Arrange
      use _ <- result.try(
        described(readme_load_env_files.load_env_files(secrets_path)),
      )

      // Act
      let result = config.get("API_KEY")

      // Assert
      result
      |> should
      |> be_equal(Ok("secret-from-the-platform"))
      |> or_fail_with("API_KEY should come from the secrets file")
    }),
    it("step 4: the secrets file wins over .env", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, ".env"))
      use _ <- result.try(
        described(readme_load_env_files.load_env_files(secrets_path)),
      )

      // Act
      let result = config.get("DATABASE_URL")

      // Assert
      result
      |> should
      |> be_equal(Ok("postgres://db.internal:5432/myapp"))
      |> or_fail_with("The file loaded first should win")
    }),
    it("step 4: .env sets the names that the secrets file does not have", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, ".env"))
      use _ <- result.try(
        described(readme_load_env_files.load_env_files(secrets_path)),
      )

      // Act
      let result = config.get("PORT")

      // Assert
      result
      |> should
      |> be_equal(Ok("8080"))
      |> or_fail_with("PORT should come from the .env file")
    }),
    it("errors: the file does not exist", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/does_not_exist.env")

      // Assert
      result
      |> should
      |> be_equal(Error(FileNotFound("test/fixtures/does_not_exist.env")))
      |> or_fail_with("load_env_files should return the error")
    }),
    it("errors: the text when the file does not exist", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/does_not_exist.env")
        |> result.map_error(config.describe_load_error)

      // Assert
      result
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/does_not_exist.env: the file does not exist",
      ))
      |> or_fail_with("describe_load_error should give the path and the reason")
    }),
    it("errors: a line has no =", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/missing_equals.env")

      // Assert
      result
      |> should
      |> be_equal(Error(MissingEquals("test/fixtures/missing_equals.env", 2)))
      |> or_fail_with("load_env_files should return the error")
    }),
    it("errors: the text when a line has no =", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/missing_equals.env")
        |> result.map_error(config.describe_load_error)

      // Assert
      result
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/missing_equals.env: line 2: expected NAME=VALUE",
      ))
      |> or_fail_with("describe_load_error should give the path and the reason")
    }),
    it("errors: a quote is not closed", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/unclosed_quote.env")

      // Assert
      result
      |> should
      |> be_equal(
        Error(QuoteNotClosed("test/fixtures/unclosed_quote.env", 1, DoubleQuote)),
      )
      |> or_fail_with("load_env_files should return the error")
    }),
    it("errors: the text when a quote is not closed", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/unclosed_quote.env")
        |> result.map_error(config.describe_load_error)

      // Assert
      result
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/unclosed_quote.env: line 1: the double quote is not closed",
      ))
      |> or_fail_with("describe_load_error should give the path and the reason")
    }),
    it("errors: the file is not UTF-8", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/not_utf8.env")

      // Assert
      result
      |> should
      |> be_equal(Error(FileNotUtf8("test/fixtures/not_utf8.env")))
      |> or_fail_with("load_env_files should return the error")
    }),
    it("errors: the text when the file is not UTF-8", fn() {
      // Act
      let result =
        readme_load_env_files.load_env_files("test/fixtures/not_utf8.env")
        |> result.map_error(config.describe_load_error)

      // Assert
      result
      |> should
      |> be_equal(Error(
        "Cannot load .env file at test/fixtures/not_utf8.env: the file is not valid UTF-8",
      ))
      |> or_fail_with("describe_load_error should give the path and the reason")
    }),
    it("errors: the file cannot be read", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, unreadable_path))
      use _ <- result.try(
        test_file.make_unreadable(unreadable_path)
        |> result.replace_error("Cannot change the permissions"),
      )

      // Act
      let result = readme_load_env_files.load_env_files(unreadable_path)

      // Assert
      result
      |> should
      |> be_equal(
        Error(FileNotReadable(
          "build/guide_env_files_unreadable.env",
          "permission denied",
        )),
      )
      |> or_fail_with("load_env_files should return the error")
    }),
    it("errors: the text when the file cannot be read", fn() {
      // Arrange
      use _ <- result.try(copy_file(development_path, unreadable_path))
      use _ <- result.try(
        test_file.make_unreadable(unreadable_path)
        |> result.replace_error("Cannot change the permissions"),
      )

      // Act
      let result =
        readme_load_env_files.load_env_files(unreadable_path)
        |> result.map_error(config.describe_load_error)

      // Assert
      result
      |> should
      |> be_equal(Error(
        "Cannot load .env file at build/guide_env_files_unreadable.env: permission denied",
      ))
      |> or_fail_with("describe_load_error should give the path and the reason")
    }),
    it("format: export before a name has no effect", fn() {
      // Arrange
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

      // Act
      let value = config.get("lower_name")

      // Assert
      value
      |> should
      |> be_equal(Error(NotSet("lower_name")))
      |> or_fail_with("lower_name should not be set")
    }),
    it("format: spaces around an unquoted value are trimmed", fn() {
      // Arrange
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

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
      use _ <- result.try(described(config.load_dotenv_from(format_path)))

      // Act
      let value = config.get("MULTILINE")

      // Assert
      value
      |> should
      |> be_equal(Ok("first line\nsecond line"))
      |> or_fail_with("MULTILINE should be Ok('first line\nsecond line')")
    }),
    it("format: a byte order mark at the start is skipped", fn() {
      // Arrange
      use _ <- result.try(
        described(config.load_dotenv_from(byte_order_mark_path)),
      )

      // Act
      let result = config.get("DREAM_CONFIG_TEST_VALUE")

      // Assert
      result
      |> should
      |> be_equal(Ok("after the mark"))
      |> or_fail_with("The first name should not hold the mark")
    }),
  ])
}

fn copy_file(from: String, to: String) -> Result(Nil, String) {
  use text <- result.try(
    file.read(from) |> result.map_error(file.error_to_string),
  )
  file.write(to, text) |> result.map_error(file.error_to_string)
}

fn described(loaded: Result(Nil, config.LoadError)) -> Result(Nil, String) {
  loaded |> result.map_error(config.describe_load_error)
}
