//// Release notes 2.0.0: Migration Guide
////
//// Reads a setting that must be set, but can be empty.

import dream_config/loader.{type ConfigError} as config

pub fn log_prefix() -> Result(String, ConfigError) {
  // LOG_PREFIX must be set, but an empty prefix is a valid value
  config.get("LOG_PREFIX")
}
