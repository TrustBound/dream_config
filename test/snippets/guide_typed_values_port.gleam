//// Guide: Read optional settings, numbers and flags, step 1
////
//// Uses a default only when PORT is not set. Every other error stops.

import dream_config/loader.{type ConfigError, NotSet} as config

pub fn port() -> Result(Int, ConfigError) {
  case config.get_int("PORT") {
    Error(NotSet(_)) -> Ok(3000)
    other -> other
  }
}
