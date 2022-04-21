defmodule RpcPG.Client do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)

      def execute(payload) do
        __MODULE__
        |> RpcPG.build_config(unquote(otp_app))
        |> RpcPG.execute(payload)
      end

      def supervisor_spec(as: name) do
        opts =
          __MODULE__
          |> RpcPG.build_config(unquote(otp_app))
          |> Keyword.merge(name: name)

        {RpcPG.ClientSupervisor, opts}
      end
    end
  end
end
