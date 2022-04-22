defmodule RpcPG.ServerCallbackTest do
  use ExUnit.Case

  @config group: "client_test"

  setup do
    Application.put_env(:rpc_test, __MODULE__.Server, @config)

    on_exit(fn -> Application.delete_env(:rpc_test, __MODULE__.Server) end)
  end

  defmodule Server do
    use RpcPG.ServerCallback, otp_app: :rpc_test

    @impl true
    def reply(payload) do
      {:ok, payload}
    end
  end

  describe "supervisor_spec/1" do
    test "returns a spec based off of the application config" do
      assert {RpcPG.ServerSupervisor, [group: "client_test", name: Test]} =
               Server.supervisor_spec(as: Test)
    end
  end
end
