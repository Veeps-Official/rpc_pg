defmodule RpcPG.ClientTest do
  use ExUnit.Case

  @config group: "client_test", server_callback: __MODULE__.ServerMock

  setup do
    Application.put_env(:rpc_test, __MODULE__.Client, @config)

    :pg.start_link(:rpc_pg)

    on_exit(fn -> Application.delete_env(:rpc_test, __MODULE__.Client) end)
  end

  defmodule(Client, do: use(RpcPG.Client, otp_app: :rpc_test))

  defmodule ServerMock do
    use RpcPG.ServerCallback, otp_app: :rpc_test

    def reply(payload) do
      {:ok, payload}
    end
  end

  describe "execute/1" do
    @tag capture_log: true
    test "returns result from server" do
      RpcPG.join_group(@config[:group])

      assert {:ok, :rpc, "test payload"} = Client.execute("test payload")
    end
  end

  describe "supervisor_spec/1" do
    test "returns a spec based off of the application config" do
      assert {RpcPG.ClientSupervisor,
              [group: "client_test", server_callback: RpcPG.ClientTest.ServerMock, name: Test]} =
               Client.supervisor_spec(as: Test)
    end
  end
end
