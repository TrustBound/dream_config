//// The output files of the guides, in `test/outputs/`. A guide shows the
//// file in a `text` block, and a test compares the file with the real
//// output of the snippet.

import dream_test/file
import gleam/result
import gleam/string

/// Reads the output file `test/outputs/<name>.txt`.
///
/// Returns `Error(String)` with the reason when the file cannot be read.
pub fn read(name: String) -> Result(String, String) {
  file.read("test/outputs/" <> name <> ".txt")
  |> result.map_error(file.error_to_string)
}

/// The text of a value as an output file holds it: what `string.inspect`
/// gives for the value, with a line break at the end.
pub fn inspected(value: a) -> String {
  string.inspect(value) <> "\n"
}
