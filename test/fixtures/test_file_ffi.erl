-module(test_file_ffi).

-export([make_unreadable/1]).

%% Removes every permission from the file at Path.
%% Returns {ok, nil} or {error, nil}.
make_unreadable(Path) ->
    case file:change_mode(Path, 8#000) of
        ok -> {ok, nil};
        {error, _Reason} -> {error, nil}
    end.
