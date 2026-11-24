-module(child_process_ffi).

-export([run_main/1]).

%% Runs Module:main() in a new erl, then halts it with status 0 if main
%% returns. Returns {ExitStatus, Output}.
run_main(Module) ->
    Erl = os:find_executable("erl"),
    Paths = filelib:wildcard("build/dev/erlang/*/ebin"),
    Eval = binary_to_list(Module) ++ ":main(), erlang:halt(0).",
    Port = open_port(
        {spawn_executable, Erl},
        [{args, ["-noshell", "-pa" | Paths] ++ ["-eval", Eval]},
         exit_status, stderr_to_stdout, binary]
    ),
    collect(Port, <<>>).

collect(Port, Output) ->
    receive
        {Port, {data, Data}} -> collect(Port, <<Output/binary, Data/binary>>);
        {Port, {exit_status, Status}} -> {Status, Output}
    end.
