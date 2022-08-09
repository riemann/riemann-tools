#!/usr/bin/env escript
%%! -name riakstatuscheck -setcookie riak -hidden

main([]) -> main(["riak@127.0.0.1"]);
main([Node]) ->
  io:format("~p\n", [
    rpc:call(list_to_atom(Node), riak_kv_console, ringready, [[]])
  ]).
