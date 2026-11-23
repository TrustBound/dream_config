//// Guide: Getting started, step 3
////
//// Loads the settings once in main, and stops with a clear message when a
//// setting is missing or wrong.

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
  use settings <- result.try(load_settings())
  Ok(serve(settings))
}

fn serve(settings: Settings) -> String {
  "Listening on port " <> int.to_string(settings.port)
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
