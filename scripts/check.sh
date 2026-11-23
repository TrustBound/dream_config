#!/bin/sh
# What CI runs: the format check, the build, the tests, the docs build, the
# snippet check and the program of the getting started guide. "make check"
# runs this script.
set -eu

gleam format --check src test
gleam build
gleam test
gleam docs build
gleam run -m dream_snippets
DATABASE_URL=postgres://localhost/app PORT=8080 gleam run -m snippets/guide_getting_started_main
