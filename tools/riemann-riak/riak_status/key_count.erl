#!/usr/bin/env escript
%%! -name riakstatuscheck -setcookie riak -hidden

main([]) -> main(["riak@127.0.0.1"]);
main([Node]) ->
  io:format("~w\n", [
    lists:foldl(
      fun({_VNode, Count}, Sum) -> Sum + Count end,
      0,
      rpc:call(list_to_atom(Node), riak_kv_bitcask_backend, key_counts, [])
    )
  ]).
