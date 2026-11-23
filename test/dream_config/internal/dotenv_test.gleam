//// Tests for the `.env` parser in `dream_config/internal/dotenv`.

import dream_config/internal/dotenv.{
  Backtick, DoubleQuote, EmptyName, MissingEquals, QuoteNotClosed, SingleQuote,
  TextAfterClosingQuote, Variable,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}

pub fn tests() -> TestSuite {
  describe("dream_config/internal/dotenv", [
    group("parse", [
      it("reads name and value pairs", fn() {
        // Act
        let result = dotenv.parse("FIRST=one\nSECOND = two \n")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("FIRST", "one"), Variable("SECOND", "two")]))
        |> or_fail_with("parse should read both variables, trimmed")
      }),
      it("reads a value at the end of the text without a line break", fn() {
        // Act
        let result = dotenv.parse("NAME=value")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("NAME", "value")]))
        |> or_fail_with("parse should read the last line without a line break")
      }),
      it("changes names to upper case", fn() {
        // Act
        let result = dotenv.parse("database_url=postgres://localhost/app")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("DATABASE_URL", "postgres://localhost/app")]))
        |> or_fail_with("parse should change the name to upper case")
      }),
      it("skips comments, empty lines, indentation and export", fn() {
        // Act
        let result =
          dotenv.parse(
            "# a comment\n\n  \n\texport NAME=value # trailing comment\n# end",
          )

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("NAME", "value")]))
        |> or_fail_with("parse should read only NAME")
      }),
      it("reads an empty value", fn() {
        // Act
        let result = dotenv.parse("EMPTY=\nCOMMENT_ONLY=# nothing\n")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("EMPTY", ""), Variable("COMMENT_ONLY", "")]))
        |> or_fail_with("parse should read both values as empty")
      }),
      it("reads double quoted, single quoted and backtick values", fn() {
        // Act
        let result =
          dotenv.parse(
            "DOUBLE=\"a # b \\\" c\\nd\"\nSINGLE=' x \\' y '\nBACKTICK=`p \\` q`\n",
          )

        // Assert
        result
        |> should
        |> be_equal(
          Ok([
            Variable("DOUBLE", "a # b \" c\nd"),
            Variable("SINGLE", " x ' y "),
            Variable("BACKTICK", "p ` q"),
          ]),
        )
        |> or_fail_with("parse should read the three quoted values")
      }),
      it("reads spaces, tabs and a comment after a closing quote", fn() {
        // Act
        let result = dotenv.parse("KEY=\"value\" \t# comment\nNEXT='x'")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("KEY", "value"), Variable("NEXT", "x")]))
        |> or_fail_with("parse should skip the text after the closing quote")
      }),
      it("reads a quoted value over several lines", fn() {
        // Act
        let result = dotenv.parse("KEY=\"line one\nline two\"\nNEXT=x\n")

        // Assert
        result
        |> should
        |> be_equal(
          Ok([Variable("KEY", "line one\nline two"), Variable("NEXT", "x")]),
        )
        |> or_fail_with("parse should keep the line break in the value")
      }),
      it("counts the lines inside a quoted value", fn() {
        // Act
        let result = dotenv.parse("KEY=\"line one\nline two\"\nBROKEN\n")

        // Assert
        result
        |> should
        |> be_equal(Error(MissingEquals(3)))
        |> or_fail_with("parse should report line 3")
      }),
      it("reads Windows line endings", fn() {
        // Act
        let result = dotenv.parse("FIRST=one\r\nSECOND=two\r\n")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("FIRST", "one"), Variable("SECOND", "two")]))
        |> or_fail_with("parse should read \\r\\n as a line break")
      }),
      it("returns an error for an empty name", fn() {
        // Act
        let result = dotenv.parse("OK=1\n=value\n")

        // Assert
        result
        |> should
        |> be_equal(Error(EmptyName(2)))
        |> or_fail_with("parse should reject an empty name on line 2")
      }),
      it("returns an error for a name without = at the end of the text", fn() {
        // Act
        let result = dotenv.parse("OK=1\nNAME")

        // Assert
        result
        |> should
        |> be_equal(Error(MissingEquals(2)))
        |> or_fail_with("parse should reject NAME on line 2")
      }),
      it("returns the opening line for a single quote that is not closed", fn() {
        // Act
        let result = dotenv.parse("OK=1\nKEY='open\nmore\n")

        // Assert
        result
        |> should
        |> be_equal(Error(QuoteNotClosed(2, SingleQuote)))
        |> or_fail_with("parse should report the single quote on line 2")
      }),
      it("returns an error for a backtick that is not closed", fn() {
        // Act
        let result = dotenv.parse("KEY=`open")

        // Assert
        result
        |> should
        |> be_equal(Error(QuoteNotClosed(1, Backtick)))
        |> or_fail_with("parse should report the backtick on line 1")
      }),
      it("returns an error for text after a closing quote", fn() {
        // Act
        let result = dotenv.parse("KEY=\"value\" extra\n")

        // Assert
        result
        |> should
        |> be_equal(Error(TextAfterClosingQuote(1, DoubleQuote)))
        |> or_fail_with("parse should reject text after the closing quote")
      }),
      it("skips one byte order mark at the start of the text", fn() {
        // Act
        let result = dotenv.parse("\u{FEFF}NAME=value\n")

        // Assert
        result
        |> should
        |> be_equal(Ok([Variable("NAME", "value")]))
        |> or_fail_with("parse should not put the mark in the first name")
      }),
    ]),
  ])
}
