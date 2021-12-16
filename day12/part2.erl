
-module(part2).
-export([start/0]).

-record(path, {
    visited = [],
    can_revisit_small = false
}).

new_path() ->
    #path{}.

visit(Cave, Path1) ->
    Path2 = Path1#path{visited = [Cave | Path1#path.visited]},
    case not is_big_cave(Cave) andalso lists:member(Cave, Path1#path.visited) of
        false -> Path2;
        true -> Path2#path{can_revisit_small = true}
    end.

can_visit(NewCave, Path) ->
    (not is_limited_cave(NewCave) andalso not Path#path.can_revisit_small) orelse
        is_big_cave(NewCave) orelse
        not lists:member(NewCave, Path#path.visited).

new_graph() ->
    dict:new().

% Note: We're assuming these are undirected graphs, so any edge added
% will also automatically add its obverse.
add_edge(G1, U, V) ->
    G2 = dict:append(U, V, G1),
    dict:append(V, U, G2).

out_edges(G, U) ->
    dict:fetch(U, G).

is_limited_cave(Cave) ->
    lists:member(Cave, ["start", "end"]).

is_big_cave(Cave) ->
    string:uppercase(Cave) =:= Cave.

walk_branches([], _, _) ->
    0;
walk_branches([Current | T], Path, Graph) ->
    N1 = walk(Current, Path, Graph),
    N2 = walk_branches(T, Path, Graph),
    N1 + N2.

walk("end", _Path, _Graph) ->
    1;
walk(Current, Path, Graph) ->
    NewPath = visit(Current, Path),
    AllBranches = out_edges(Graph, Current),
    Branches = lists:filter(fun(B) -> can_visit(B, NewPath) end, AllBranches),
    walk_branches(Branches, NewPath, Graph).

load_file(File) ->
    {ok, IO} = file:open(File, [read]),
    Read = load_file(io:get_line(IO, ''), IO, new_graph()),
    file:close(File),
    Read.

load_file(eof, _, G) ->
    G;
load_file(Line, IO, G1) ->
    [Lhs, Rhs] = string:tokens(string:trim(Line), "-"),
    G2 = add_edge(G1, Lhs, Rhs),
    load_file(io:get_line(IO, ''), IO, G2).

% Entrypoint; run this function :)
start() ->
    Graph = load_file("input.txt"),
    AllPaths = walk("start", new_path(), Graph),
    io:fwrite("~B~n", [AllPaths]).
