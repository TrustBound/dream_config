//// Guide: Optional settings, numbers and flags, step 2
////
//// Reads an optional port that must be a number when it is set.

import dream_config/loader as config

pub fn port() -> Result(Int, String) {
  case config.get("PORT") {
    Error(Nil) -> Ok(3000)
    Ok(_) -> config.get_required_int("PORT")
  }
}
