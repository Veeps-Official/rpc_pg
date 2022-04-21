defmodule RpcPGTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  doctest RpcPG

  describe "join_group/1" do
    setup do
      :pg.start_link(RpcPG.pg_scope())

      :ok
    end

    test "adds when group is empty" do
      assert [] == :pg.get_local_members(RpcPG.pg_scope(), "unit")

      pid = self()

      {_result, log} =
        with_log(fn ->
          RpcPG.join_group("unit")
        end)

      assert [^pid] = :pg.get_local_members(RpcPG.pg_scope(), "unit")
      assert log =~ ~s(RpcPG.Server:join group: "unit")
    end

    test "adds at most once" do
      pid = self()

      {_result, log} =
        with_log(fn ->
          RpcPG.join_group("unit")
        end)

      RpcPG.join_group("unit")

      assert [^pid] = :pg.get_local_members(RpcPG.pg_scope(), "unit")
      assert log =~ ~s(RpcPG.Server:join group: "unit")
    end
  end

  test "pg_scope/0 returns :rpc_pg" do
    assert :rpc_pg == RpcPG.pg_scope()
  end
end
