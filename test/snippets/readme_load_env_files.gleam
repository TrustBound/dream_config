//// Guide: Use a .env file in development
////
//// Loads a secrets file from a path, then the .env file in the current
//// directory.

import dream_config/loader.{type LoadError} as config
import gleam/result

pub fn load_env_files(secrets_path: String) -> Result(Nil, LoadError) {
  // The first value for a name wins, so load the most important file first
  use _ <- result.try(config.load_dotenv_from(secrets_path))

  // Then the local .env file, for the names that are still not set
  config.load_dotenv()
}
