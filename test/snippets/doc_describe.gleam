//// Doc comment: loader.describe
////
//// Turns a ConfigError into the text for a log line.

import dream_config/loader as config

pub fn port_problem() -> String {
  case config.get_required_int("PORT") {
    Ok(_) -> "PORT is valid"
    Error(error) -> config.describe(error)
  }
}
