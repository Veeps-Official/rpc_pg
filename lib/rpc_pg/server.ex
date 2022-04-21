defmodule RpcPG.Server do
  use GenServer

  require Logger

  def start_link(config) do
    GenServer.start(__MODULE__, config, name: __MODULE__)
  end

  @impl GenServer
  def init(config) do
    group = Keyword.fetch!(config, :group)

    RpcPG.join_group(group)

    {:ok, config}
  end
end
