-module(flat_tree_basics).
-include_lib("eunit/include/eunit.hrl").

index_test() ->
    %% {Expected, {Depth, Offset}}
    Data = [
        {0, {0, 0}},
        {2, {0, 1}},
        {4, {0, 2}},
        {9, {1, 2}},
        {13, {1, 3}},
        {11, {2, 1}},
        {19, {2, 2}},
        {7, {3, 0}},
        {23, {3, 1}}
    ],
    true = lists:all(
        fun({Expected, {Depth, Offset}}) ->
            Expected =:= flat_tree:index(Depth, Offset)
        end,
        Data
    ).

depth_test() ->
    %% {Index, ExpectedDepth}
    Data = [
        {0, 0},
        {1, 1},
        {3, 2},
        {7, 3},
        {4, 0},
        {5, 1}
    ],
    true = lists:all(
        fun({Index, Expected}) ->
            Expected =:= flat_tree:depth(Index)
        end,
        Data
    ).

offset_test() ->
    %% {Index, Expected}
    Data = [
        {0, 0},
        {1, 0},
        {3, 0},
        {7, 0},
        {2, 1},
        {5, 1},
        {11, 1},
        {4, 2}
    ],
    true = lists:all(
        fun({Index, Expected}) ->
            Expected =:= flat_tree:offset(Index)
        end,
        Data
    ).

parent_test() ->
    %% {Index, Expected}
    Data = [
        {0, 1},
        {2, 1},
        {3, 7},
        {4, 5},
        {5, 3},
        {13, 11},
        {14, 13}
    ],
    true = lists:all(
        fun({Index, Expected}) ->
            Expected =:= flat_tree:parent(Index)
        end,
        Data
    ).

sibling_test() ->
    %% {Index, Expected}
    Data = [
        {0, 2},
        {2, 0},
        {1, 5},
        {5, 1},
        {13, 9},
        {12, 14},
        {3, 11}
    ],
    true = lists:all(
        fun({Index, Expected}) ->
            Expected =:= flat_tree:sibling(Index)
        end,
        Data
    ).

uncle_test() ->
    % {Index, Expected}
    Data = [
        {0, 5},
        {4, 1},
        {5, 11},
        {9, 3},
        {10, 13}
    ],
    true = lists:all(
        fun({Index, Expected}) ->
            Expected =:= flat_tree:uncle(Index)
        end,
        Data
    ).

children_test() ->
    none = flat_tree:children(0),
    {3, 11} = flat_tree:children(7),
    {9, 13} = flat_tree:children(11).

leftchild_test() ->
    none = flat_tree:left_child(0),
    4 = flat_tree:left_child(5),
    9 = flat_tree:left_child(11),
    3 = flat_tree:left_child(7),
    none = flat_tree:left_child(4),
    ok.

rightchild_test() ->
    none = flat_tree:right_child(6),
    6 = flat_tree:right_child(5),
    11 = flat_tree:right_child(7),
    ok.

leftspan_test() ->
    ok.

rightspan_test() ->
    ok.
