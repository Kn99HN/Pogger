defmodule Reconciliation.Tree do

alias __MODULE__
@enforce_keys [:node, :parent, :children]

defstruct(
    node: nil,
    parent: nil,
    children: nil
)


end