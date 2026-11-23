//// Guide: Optional settings, numbers and flags, step 4
////
//// Reads a required number and checks that it is in a range.

import dream_config/loader as config
import gleam/int
import gleam/result

pub fn pool_size() -> Result(Int, String) {
  use size <- result.try(config.get_required_int("POOL_SIZE"))
  case size >= 1 && size <= 100 {
    True -> Ok(size)
    False ->
      Error("POOL_SIZE must be from 1 to 100, got " <> int.to_string(size))
  }
}
