defmodule RpcPG.ServerCallback do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour RpcPG.ServerCallbackBehaviour

      otp_app = Keyword.fetch!(opts, :otp_app)

      def supervisor_spec(as: name) do
        opts =
          __MODULE__
          |> RpcPG.build_config(unquote(otp_app))
          |> Keyword.merge(name: name)

        {RpcPG.ServerSupervisor, opts}
      end

      def handle_rpc(from_pid, caller_params) do
        RpcPG.rpc_pg_handle_reply(
          :timer.tc(__MODULE__, :reply, [caller_params]),
          __MODULE__,
          from_pid
        )
      end
    end
  end
end
