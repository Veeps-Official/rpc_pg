defmodule RpcPG.ServerCallback do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour RpcPG.ServerCallbackBehaviour

      otp_app = Keyword.fetch!(opts, :otp_app)

      def supervisor_spec(as: name) do
        opts =
          __MODULE__
          |> RpcPG.Server.build_config(unquote(otp_app))
          |> Keyword.merge(name: name)

        {RpcPG.ServerSupervisor, opts}
      end

      def handle_rpc(from_pid, caller_params) do
        case reply(caller_params) do
          {:ok, response} ->
            send(from_pid, {:rpc_pg_success, response})

          {:error, error_response} ->
            send(from_pid, {:rpc_pg_failure, error_response})
        end
      end
    end
  end
end
