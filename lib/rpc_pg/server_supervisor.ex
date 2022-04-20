defmodule RpcPG.ServerSupervisor do
  use Supervisor

  alias RpcPG.Server

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    children = [
      %{
        id: :pg,
        start: {:pg, :start_link, [RpcPG.pg_scope()]}
      },
      {Server, config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
