defmodule SingleFileAppLogger do
  @moduledoc """
  Just some Logger assistance in the absence of a full Mix environment/config.
  Allows passthrough of log level environment vars to the elixir Logger.
  """
  defmacro __using__(_opts) do
    quote do
      require Logger
      user_set_env = System.get_env("ELIXIR_LOGLEVEL")
      if user_set_env do
        Application.put_env(:logger, :compile_time_purge_level, user_set_env |> String.to_atom)
      else
        Application.put_env(:logger, :compile_time_purge_level, :info)
      end
    end
  end
end