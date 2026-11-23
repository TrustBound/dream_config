//// Doc comment: loader.load_dotenv
////
//// Loads the .env file, then reads a required value.

import dream_config/loader as config
import gleam/result

pub fn database_url_at_startup() -> Result(String, String) {
  // A missing .env file is not an error, a malformed one is
  use _ <- result.try(
    config.load_dotenv() |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
