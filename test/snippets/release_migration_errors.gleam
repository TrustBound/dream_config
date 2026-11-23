//// Release notes 2.0.0: Migration Guide
////
//// Matches on the error value instead of the text of a message.

import dream_config/loader.{Empty, NotAnInteger, NotSet} as config

pub fn port_hint() -> String {
  case config.get_required_int("PORT") {
    Ok(_) -> "PORT is valid"
    Error(NotSet(_)) -> "Set PORT, for example PORT=8080"
    Error(Empty(_)) -> "PORT is empty"
    Error(NotAnInteger(_, value)) -> "PORT is not a number: " <> value
  }
}
