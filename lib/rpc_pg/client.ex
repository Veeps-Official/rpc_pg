defmodule RpcPG.Client do
  @moduledoc """
  Client functions for RPC across nodes.

  Adds `execute/1`, and `supervisor_spec1` functions to the mmodule
  in which it is used.

  See the ["Getting Started" section of the README][getting-started] for an
  example of how to set up and configure a client for use.

  [getting-started]: https://hexdocs.pm/rpc_pg/readme.html#getting-started

  ## Example
  Creating a Client is as simple as defining a module in your application and
  using `RpcPG.Client`.

      # some/path/within/your/app/rpc_client.ex
      defmodule MyApp.RpcCLient do
        use RpcPG.Client, otp_app: :my_app
      end

  The client requires some configuration within your application.

      # config/config.exs
      config :my_app, MyApp.RpcClient,
        group: "my_group", # Specify the process group this client will broadcast to.
        server_callback: MyOtherApp.Server # Specify the server that implements the ServerCallback behaviour.
  """
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
