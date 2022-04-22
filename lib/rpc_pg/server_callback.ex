defmodule RpcPG.ServerCallback do
  @moduledoc """
  Server function and behaviour for RPC across nodes.

  See the ["Getting Started" section of the README][getting-started] for an
  example of how to set up and configure a server for use.

  [getting-started]: https://hexdocs.pm/rpc_pg/readme.html#getting-started

  ## Example
  Creating a Server is as simple as defining a module in your application and
  using `RpcPG.ServerCallback`.

      # some/path/within/your/app/rpc_server.ex
      defmodule MyApp.RpcServer do
        use RpcPG.ServerCallback, otp_app: :my_app

        @impl true
        def reply(payload) do
          # The body of your server's reply function must return: {:ok, any()} | {:error, any()}
        end
      end

  The client requires some configuration within your application.

      # config/config.exs
      config :my_app, MyApp.RpcServer,
        group: "my_group", # Specify the process group this server will receive from.
  """
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
