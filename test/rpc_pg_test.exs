defmodule RpcPGTest do
  use ExUnit.Case
  doctest RpcPG

  test "greets the world" do
    assert RpcPG.hello() == :world
  end
end
