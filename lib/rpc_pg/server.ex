defmodule RpcPG.Server do
  use GenServer

  require Logger

  def start_link(config) do
    GenServer.start(__MODULE__, config, name: __MODULE__)
  end

  @impl GenServer
  def init(config) do
    group = Keyword.fetch!(config, :group)

    RpcPG.join_group(group, role: :server)

    {:ok, config}
  end

  def build_config(client, otp_app) do
    Application.fetch_env!(otp_app, client)
  end
end
