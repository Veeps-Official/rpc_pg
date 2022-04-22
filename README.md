# RpcPG

Simple process group based client/server RPC. Born out of a need to talk to specific nodes within a mesh connected using libcluster.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rpc_pg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rpc_pg, "~> 0.1.0"}
  ]
end
```

## Getting Started

RpcPG requires config on both the server and client applications. To use the library
you'll need to define a client module and a server callback module in each respective app.


### Client config

To call a server, define a Client module for your application that `use`s
RpcPG's Client.

```elixir
# some/path/within/your/app/client.ex
defmodule MyApp.Client do
  use RpcPG.Client, otp_app: :my_app
end
```

Your configuration will need to know your OTP application, your client module,
the server group you wish to RPC to and the module that uses `RpcPG.ServerCallback`
adapter itself.

```elixir
# config/config.exs
config :my_app, MyApp.Client,
  group: "emails",
  server_callback: OtherApp.RPCServer
```

### Server config

To build a server reply for clients in an existing group, define a server callback module for your application that `use`s
RpcPG's ServerCallback.

```elixir
# some/path/within/your/app/server.ex
defmodule MyApp.Server do
  use RpcPG.ServerCallback, otp_app: :my_app

  @impl true
  def reply(payload) do
    # This function _must_ return: {:ok, any()} | {:error, any()}
  end
end
```

Your configuration will need to know your OTP application, your server module,
and the group you wish to receive messages from clients.

```elixir
# config/config.exs
config :my_app, MyApp.Server,
  group: "emails"
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/rpc_pg>.

