//// Doc comment: loader.load_dotenv_override_from
////
//// Loads a .env file from a given path over the variables that are set.

import dream_config/loader.{type LoadError} as config

pub fn load_profile(path: String) -> Result(Nil, LoadError) {
  // For example "config/staging.env". Its values replace the ones that are set.
  config.load_dotenv_override_from(path)
}
