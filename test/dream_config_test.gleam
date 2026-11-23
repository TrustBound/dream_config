//// Runs every test of dream_config with coverage.
////
//// The tests set and unset environment variables of the whole BEAM and write
//// `.env` files, so they run one at a time.

import architecture_snippets_test
import deployment_guide_snippets_test
import doc_snippets_test
import dream_config/internal/dotenv_test
import dream_config/loader_test
import dream_test/coverage
import dream_test/reporters/bdd
import dream_test/reporters/progress
import dream_test/runner
import guide_env_files_test
import guide_getting_started_test
import guide_typed_values_test
import readme_snippets_test
import release_notes_snippets_test
import snippets/guide_env_files_testing
import snippets/guide_getting_started_testing
import snippets/guide_typed_values_testing

pub fn main() {
  runner.new([
    loader_test.tests(),
    dotenv_test.tests(),
    readme_snippets_test.tests(),
    doc_snippets_test.tests(),
    release_notes_snippets_test.tests(),
    architecture_snippets_test.tests(),
    deployment_guide_snippets_test.tests(),
    guide_getting_started_test.tests(),
    guide_getting_started_testing.tests(),
    guide_env_files_test.tests(),
    guide_env_files_testing.tests(),
    guide_typed_values_test.tests(),
    guide_typed_values_testing.tests(),
  ])
  |> runner.max_concurrency(1)
  |> runner.progress_reporter(progress.new())
  |> runner.results_reporters([bdd.new()])
  |> runner.coverage(
    coverage.new()
    |> coverage.show_missing()
    |> coverage.minimum_percent(100.0)
    |> coverage.json_path("build/coverage/coverage.json"),
  )
  |> runner.exit_on_failure()
  |> runner.run()
}
