//// Doc comment: loader.describe_load_error
////
//// Turns a LoadError into the text for a log line.

import dream_config/loader as config
import gleam/result

pub fn load_or_explain(path: String) -> Result(Nil, String) {
  config.load_dotenv_from(path)
  |> result.map_error(config.describe_load_error)
}
