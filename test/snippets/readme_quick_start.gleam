//// README: Quick Start
////
//// Reads the required and the optional settings into one record.

import dream_config/loader.{type ConfigError} as config
import gleam/result

pub type Settings {
  Settings(database_url: String, port: Int, debug_mode: Bool, api_key: String)
}

pub fn load_settings() -> Result(Settings, ConfigError) {
  // Required: the error names the variable that is not set, empty or wrong
  use database_url <- result.try(config.get_required("DATABASE_URL"))
  use port <- result.try(config.get_required_int("PORT"))

  // Optional, with defaults
  let debug_mode = config.get_bool("DEBUG")
  let api_key = config.get("API_KEY") |> result.unwrap("default-key")

  Ok(Settings(database_url:, port:, debug_mode:, api_key:))
}
