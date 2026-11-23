//// Doc comment: loader.load_dotenv_override
////
//// Loads the .env file over the variables that are set, then reads a value.

import dream_config/loader as config
import gleam/result

pub fn database_url_from_file() -> Result(String, String) {
  // The value in the .env file replaces a variable that is already set
  use _ <- result.try(
    config.load_dotenv_override()
    |> result.map_error(config.describe_load_error),
  )
  config.get_required("DATABASE_URL") |> result.map_error(config.describe)
}
