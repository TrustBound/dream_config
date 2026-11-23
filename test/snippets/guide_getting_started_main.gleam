//// Guide: Getting started, step 3
////
//// Loads the .env file and the settings once, then starts the app or stops
//// with the reason.

import dream_config/loader as config
import gleam/int
import gleam/io
import gleam/result
import snippets/readme_quick_start.{type Settings, load_settings}

pub fn main() -> Nil {
  case start() {
    Ok(message) -> io.println(message)
    Error(reason) -> {
      io.println_error("Cannot start: " <> reason)
      halt(1)
    }
  }
}

pub fn start() -> Result(String, String) {
  // Local values. A variable that is already set keeps its value.
  use _ <- result.try(
    config.load_dotenv() |> result.map_error(config.describe_load_error),
  )
  use settings <- result.try(
    load_settings() |> result.map_error(config.describe),
  )
  Ok(serve(settings))
}

fn serve(settings: Settings) -> String {
  "Listening on port " <> int.to_string(settings.port)
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
