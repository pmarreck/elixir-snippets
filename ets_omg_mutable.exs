defmodule OMGMutable do
  @moduledoc """
  Provides a cheap Elixir wrapper to the Erlang Term Storage datastore.
  """

  @table "OMGMutable_#{inspect self}" |> String.to_atom
  @default_args [:set, :public, :named_table]

  @doc """
  Initialize the datastore.
  """
  def start(args \\ @default_args) do
    if info == :undefined do
      :ets.new(@table, args)
    end
    :ok
  end

  @doc """
  Returns value (body) from the key (client key).
  """
  def get(key) do
    start
    :ets.lookup(@table, key)[key]
  end

  @doc """
  Set value (body) with the key (client key).
  """
  def set(key, value) do
    start
    :ets.insert(@table, {key, value})
    value
  end

  @doc """
  Delete key (client key).
  """
  def delete(key) do
    start
    :ets.delete(@table, key)
  end

  def info do
    :ets.info(@table)
  end

  def i do
    :ets.i
  end

  def i(tab) do
    :ets.i(tab)
  end

  def table do
    @table
  end

  def tables do
    :ets.all
  end

  def all do
    :ets.tab2list(@table)
  end

  def all(table) do
    :ets.tab2list(table)
  end

  def load(filename \\ "omg_mutable") do
    :ets.file2tab(to_char_list((filename <> "_") <> to_string(@table)))
  end

  def dump(filename \\ "omg_mutable", table \\ @table) do
    :ets.tab2file(table, to_char_list((filename <> "_") <> to_string(table)))
  end

  def drop(table \\ @table) do
    :ets.delete(table)
  end

end