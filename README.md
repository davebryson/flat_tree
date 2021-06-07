# flat_tree
A pure Erlang implementation of a flat tree as described here: https://github.com/datrs/flat-tree

## Build
    $ make build
    or 
    $ rebar3 compile

## What does a flat-tree do?
A Flat Tree is a deterministic way of using a list as an index
for nodes in a tree. Essentially a simpler way of representing the
position of nodes.

A Flat Tree is also refered to as 'bin numbers' described here
in RFC 7574: https://datatracker.ietf.org/doc/html/rfc7574#section-4.2

As an example (from the RFC), here's a tree with a width of 8 leafs
and a depth of 3:

```text
         3                     (7)
                             /     \
                            /       \
                           /         \
                          /           \
         2              3              11
                       / \              / \
                      /   \            /   \
                     /     \          /     \
         1         1       5        9       13
                  / \     / \      / \      / \
   Depth 0       0   2   4   6    8   10  12   14
                 C0  C1  C2  C3    C4  C5  C6   C7

                  The flat tree is the list [0..14]
                  The content (leafs) are C0..C7
```

Using the flat tree, we can see index:
- 7 represents all the content (C0..C7)
- 1 represents C0 and C1
- 3 represent C0..C3
- ...etc...

Even numbers are always leafs at depth 0  and odd numbers are parents at depths > 0

This code provides a libray for finding the index of nodes in a tree via the flat tree list.

Some examples using the Tree above

```erlang
  %% Find the children of index 3
  {1, 5} = flat_tree:children(3),

  %% Find the parent of index 6
  5 = flat_tree:parent(6),

  %% Find the span of index 3
  {0, 6} = flat_tree:spans(3).
```
This work is almost a direct port of the DAT rust project: https://github.com/datrs/flat-tree



