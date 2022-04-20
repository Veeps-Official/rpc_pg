defmodule RpcPG do
  @moduledoc false

  require Logger

  @pg_scope :rpc_pg
  @timeout_ms 3_000

  @spec execute(opts :: keyword(), payload :: any()) ::
          {:ok, :rpc, any()}
          | {:error, :rpc, any()}
          | {:error, :timeout}
          | {:error, :no_servers}
  def execute(opts, payload) do
    group = Keyword.fetch!(opts, :group)
    mod = Keyword.fetch!(opts, :server_callback)

    case :pg.get_members(@pg_scope, group) do
      [] ->
        {:error, :no_servers}

      servers ->
        from = self()

        servers
        |> Enum.random()
        |> node()
        |> tap(fn node_name ->
          Logger.info("SELECTED: #{inspect(node_name)}")
        end)
        |> Node.spawn(mod, :handle_rpc, [from, payload])

        receive do
          {:rpc_pg_success, message} ->
            {:ok, :rpc, message}

          {:rpc_pg_failure, message} ->
            {:error, :rpc, message}
        after
          @timeout_ms ->
            {:error, :timeout}
        end
    end
  end

  @doc false
  def join_group(_group, role: :client), do: nil

  def join_group(group, role: :server) do
    pid = self()

    @pg_scope
    |> :pg.get_local_members(group)
    |> case do
      [] ->
        true

      list ->
        pid not in list
    end
    |> if do
      Logger.info("RpcPG.Server:join group: #{inspect(group)}")

      :ok = :pg.join(@pg_scope, group, pid)
    end
  end

  @doc false
  def pg_scope, do: @pg_scope
end
