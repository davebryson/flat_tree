%%% @doc A Flat Tree is a deterministic way of using a list as an index
%%% for nodes in a tree. Essentially a simpler way of representing the
%%% position of nodes.
%%%
%%% A Flat Tree is also refered to as 'bin numbers' described here
%%% in RFC 7574: https://datatracker.ietf.org/doc/html/rfc7574#section-4.2
%%%
%%% As an example (from the RFC), here's a tree with a width of 8 leafs
%%% and a depth of 3:
%%%
%%%         3                      7
%%%                               / \
%%%                             /     \
%%%                           /         \
%%%                         /             \
%%%         2              3                11
%%%                       / \              / \
%%%                      /   \            /   \
%%%                     /     \          /     \
%%%         1         1       5        9       13
%%%                  / \     / \      / \      / \
%%%   Depth 0       0   2   4   6    8   10  12   14
%%%                 C0  C1  C2  C3    C4  C5  C6   C7
%%%
%%%                  The flat tree is the list [0..14]
%%%                  The content (leafs) is C0..C7
%%%
%%%  Using the flat tree, we can see index:
%%%   - 7 represents all the content (C0..C7)
%%%   - 1 represents C0 and C1
%%%   - 3 represent C0..C3
%%%   ... etc ...
%%%  Even numbers are always leafs at depth 0
%%%  Odd numbers are parents at depths > 0
%%%
%%% This work is almost a direct port of the DAT rust project:
%%% https://github.com/datrs/flat-tree
%%%
%%% Along with the content described here:
%%% https://datprotocol.github.io/book/ch01-01-flat-tree.html
%%% @end
-module(flat_tree).

-export([
    index/2,
    depth/1,
    offset/1,
    parent/1,
    sibling/1,
    uncle/1,
    children/1,
    left_child/1,
    right_child/1,
    left_span/1,
    right_span/1,
    spans/1,
    count/1
]).

%% @doc Find the index value at a given depth and offset from the left of the tree.
index(Depth, Offset) ->
    Offset bsl (Depth + 1) bor ((1 bsl Depth) - 1).

%% @doc Calculate the depth of the tree for a given index.
%% The root of the tree is the highest depth.
%% The leafs are always at depth 0.
%%
%% To find the depth count the number of trailing '1' bits (LSBs)
%% for the given Index.  For example, the value:
%%
%%             11000001,
%%                    ^- has a depth of 1.
%%             11000011
%%                    ^- has a depth of 2.
%%
%% Interestingly, even numbers have no trailing '1s' and
%% therefore are always at depth 0.
%%
%% Side note: Funky business converting an integer to binary...
%% the built in function (integer_to_binary) returns something different.
%% <<Index>> != integer_to_binary(Index)
%%
%% This is not the most optimal solution.  A better approach would be
%% with a lookup table.
%% Here we:
%%  - reverse the binary and push the bits on to the head of a list (Acc)
%%  - then, we count '1s' till we hit a '0'.
depth(Index) ->
    dep(<<Index>>, <<>>).
dep(<<>>, Acc) ->
    count_ones(Acc, 0);
dep(<<X:1, R/bitstring>>, Acc) ->
    dep(R, [X | Acc]).
count_ones([], Count) ->
    Count;
count_ones([H | T], Count) ->
    case H =:= 1 of
        true -> count_ones(T, Count + 1);
        _ -> Count
    end.

%% @doc Return the offset for an index from the left side of the tree.
%%
%% For example: (0, 1, 3, 7) have an offset of 0
%% (Tree is rotated to right in diagram)
%%
%% (0)┐
%%   (1)┐
%%  2─┘ │
%%     (3)┐
%%  4─┐ │ │
%%    5─┘ │
%%  6─┘   │
%%       (7)
%%
%% While (2, 5, 11) have an offset of 1:
%%  0──┐
%%     1──┐
%% (2)─┘  │
%%        3──┐
%%  4──┐  │  │
%%    (5)─┘  │
%%  6──┘     │
%%           7
%%  8──┐     │
%%     9──┐  │
%% 10──┘  │  │
%%      (11)─┘
%% 12──┐  │
%%    13──┘
%% 14──┘
%%
offset(Index) ->
    Depth = depth(Index),
    case is_even(Index) of
        true -> Index div 2;
        _ -> Index bsr (Depth + 1)
    end.

%% @doc Return the index of the parent for the given index.
parent(Index) ->
    Depth = depth(Index),
    index(Depth + 1, offset(Index) bsr 1).

%% @doc Return the index of node that shares a parent
sibling(Index) ->
    Depth = depth(Index),
    index(Depth, offset(Index) bxor 1).

%% @doc Return a parent's sibiling
uncle(Index) ->
    Depth = depth(Index),
    index(Depth + 1, offset(parent(Index)) bxor 1).

%% @doc Find the Indices of the children for a given index.
%% returns:
%% none | {left index, right index}
children(Index) ->
    Depth = depth(Index),
    find_chillin(Index, Depth).
find_chillin(Index, _Depth) when (Index band 1) =:= 0 ->
    %% The index is an even number, it's a leaf
    none;
find_chillin(Index, Depth) when Depth =:= 0 ->
    %% Still at a leaf, return the Index
    {Index, Index};
find_chillin(Index, Depth) ->
    Offset = offset(Index) * 2,
    {index(Depth - 1, Offset), index(Depth - 1, Offset + 1)}.

%% @doc Get the child to the left
%% returns:
%% none | index
left_child(Index) ->
    Depth = depth(Index),
    find_left_child(Index, Depth).
find_left_child(Index, _Depth) when (Index band 1) =:= 0 ->
    none;
find_left_child(Index, Depth) when Depth =:= 0 ->
    Index;
find_left_child(Index, Depth) ->
    index(Depth - 1, offset(Index) bsl 1).

%% @doc Get the child to the right
%% returns:
%% none | index
right_child(Index) ->
    Depth = depth(Index),
    find_right_child(Index, Depth).
find_right_child(Index, _Depth) when (Index band 1) =:= 0 ->
    none;
find_right_child(Index, Depth) when Depth =:= 0 ->
    Index;
find_right_child(Index, Depth) ->
    index(Depth - 1, (offset(Index) bsl 1) + 1).

%% @doc The index of the left most node in the span
left_span(Index) ->
    Depth = depth(Index),
    l_span(Index, Depth).
l_span(Index, Depth) when Depth =:= 0 -> Index;
l_span(Index, Depth) -> offset(Index) * (2 bsl Depth).

%% @doc The index of the right most node in the span
right_span(Index) ->
    Depth = depth(Index),
    r_span(Index, Depth).
r_span(Index, Depth) when Depth =:= 0 -> Index;
r_span(Index, Depth) -> (offset(Index) + 1) * (2 bsl Depth) - 2.

%% @doc return the span of the left and right nodes for the given index.
spans(Index) ->
    {left_span(Index), right_span(Index)}.

%% Return how many nodes are in the subtee at the given index.
count(Index) ->
    Depth = depth(Index),
    (2 bsl Depth) - 1.

full_roots() ->
    %% TODO
    ok.

%%%
%%%  Private
%%%

%% Helper
%showbits(Values) ->
%    lists:foreach(fun(E) -> io:format("~.2B~n", [E]) end, Values),
%   Depths = [depth(I) || I <- [0, 1, 2, 3, 4, 5, 6, 7]],
%    io:format("Depths~n"),
%   lists:foreach(fun(E) -> io:format("~p~n", [E]) end, Depths).

is_even(Index) when is_integer(Index) ->
    (Index band 1) =:= 0.
