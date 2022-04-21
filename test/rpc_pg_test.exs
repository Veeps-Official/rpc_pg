defmodule RpcPGTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule GoodRpcResponse do
    def handle_rpc(from_pid, payload) do
      send(from_pid, {:rpc_pg_success, payload})
    end
  end

  defmodule BadRpcResponse do
    def handle_rpc(from_pid, payload) do
      send(from_pid, {:rpc_pg_failure, payload})
    end
  end

  defmodule TimeoutRpcResponse do
    def handle_rpc(_from_pid, _payload) do
      nil
    end
  end

  describe "execute/2" do
    setup do
      :pg.start_link(RpcPG.pg_scope())

      :ok
    end

    test "returns :no_servers when group is empty" do
      assert {:error, :no_servers} =
               RpcPG.execute(
                 [
                   group: "testing",
                   server_callback: nil
                 ],
                 "payload"
               )
    end

    @tag capture_log: true
    test "returns :timeout when timeout has elapsed" do
      RpcPG.join_group("testing")

      assert {:error, :timeout} =
               RpcPG.execute(
                 [
                   group: "testing",
                   server_callback: TimeoutRpcResponse,
                   timeout: 0
                 ],
                 "payload"
               )
    end

    @tag capture_log: true
    test "returns :ok when server sends :rpc_pg_success" do
      RpcPG.join_group("testing")

      assert {:ok, :rpc, "payload"} =
               RpcPG.execute(
                 [
                   group: "testing",
                   server_callback: GoodRpcResponse
                 ],
                 "payload"
               )
    end

    @tag capture_log: true
    test "returns :error when server sends :rpc_pg_failure" do
      RpcPG.join_group("testing")

      assert {:error, :rpc, "boom"} =
               RpcPG.execute(
                 [
                   group: "testing",
                   server_callback: BadRpcResponse
                 ],
                 "boom"
               )
    end
  end

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

  describe "rpc_pg_handle_reply/2" do
    test "logs when execution_time is > timeout" do
      {_result, log} =
        with_log(fn ->
          RpcPG.rpc_pg_handle_reply({3_001_000, nil}, :cb, nil)
        end)

      assert log =~ "cb.reply/1 timeout: 3001.0ms"
    end

    test "sends rpc_pg_success when result is :ok" do
      RpcPG.rpc_pg_handle_reply({100, {:ok, "good!"}}, :cb, self())

      assert_received {:rpc_pg_success, "good!"}
    end

    test "sends rpc_pg_failure when result is :error" do
      RpcPG.rpc_pg_handle_reply({100, {:error, "bad!"}}, :cb, self())

      assert_received {:rpc_pg_failure, "bad!"}
    end
  end
end
