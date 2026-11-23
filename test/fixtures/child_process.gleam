//// Run the `main` function of a module in a new BEAM, so that a test can see
//// what it prints and the status it exits with, also when it halts.

/// Runs `module:main()` in a new `erl` with the code paths of
/// `build/dev/erlang`. The new BEAM gets the environment variables of this
/// one. Returns the exit status and the text it printed to standard output
/// and standard error.
@external(erlang, "child_process_ffi", "run_main")
pub fn run_main(module: String) -> #(Int, String)
