defmodule RpcPG.ServerCallbackBehaviour do
  @callback reply(any()) :: {:ok, any()} | {:error, any()}
end
