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
          Logger.info("RpcPG:Server selected: #{inspect(node_name)}")
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
  def rpc_pg_handle_reply({execution_time, _result}, callback_module, _from)
      when execution_time > @timeout_ms,
      do: Logger.warn("#{callback_module}.reply/1 timeout: #{execution_time / 1_000}ms")

  def rpc_pg_handle_reply({_execution_time, result}, _callback_module, from_pid) do
    case result do
      {:ok, response} ->
        send(from_pid, {:rpc_pg_success, response})

      {:error, error_response} ->
        send(from_pid, {:rpc_pg_failure, error_response})
    end
  end

  @doc false
  def join_group(group) do
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
