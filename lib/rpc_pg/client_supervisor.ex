defmodule RpcPG.ClientSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(config) do
    name = Keyword.fetch!(config, :name)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  @impl Supervisor
  def init(_config) do
    children = [
      %{
        id: :pg,
        start: {:pg, :start_link, [RpcPG.pg_scope()]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
