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
import readme_snippets_test

pub fn main() {
  runner.new([
    loader_test.tests(),
    dotenv_test.tests(),
    readme_snippets_test.tests(),
    doc_snippets_test.tests(),
    architecture_snippets_test.tests(),
    deployment_guide_snippets_test.tests(),
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
