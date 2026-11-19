//// Files for the tests of `.env` loading: delete a file that a test wrote,
//// and make a file that the user cannot read.

import dream_test/file

/// Deletes the file at `path`. A file that does not exist is not an error.
///
/// Returns `Error(String)` with the reason when the file exists and cannot be
/// deleted.
pub fn delete_if_present(path: String) -> Result(Nil, String) {
  case file.delete(path) {
    Ok(Nil) | Error(file.NotFound(_)) -> Ok(Nil)
    Error(error) -> Error(file.error_to_string(error))
  }
}

/// Removes every permission from the file at `path`.
///
/// Returns `Error(Nil)` when the permissions cannot be changed.
@external(erlang, "test_file_ffi", "make_unreadable")
pub fn make_unreadable(path: String) -> Result(Nil, Nil)
