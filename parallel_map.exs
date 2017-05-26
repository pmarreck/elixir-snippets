defmodule Parallel do
  # Allows mapping over a collection using N parallel processes
  def pmap(collection, func) do
    # Get this process's PID
    me = self()
    collection
    |>
    Enum.map(fn (elem) ->
      # For each element in the collection, spawn a process and
      # tell it to:
      # - Run the given function on that element
      # - Call up the parent process
      # - Send the parent its PID and its result
      # Each call to spawn_link returns the child PID immediately.
      spawn_link fn -> (send me, { self(), func.(elem) }) end
    end) |>
    # Here we have the complete list of child PIDs. We don't yet know
    # which, if any, have completed their work
    Enum.map(fn (pid) ->
      # For each child PID, in order, block until we receive an
      # answer from that PID and return the answer
      # While we're waiting on something from the first pid, we may
      # get results from others, but we won't "get those out of the
      # mailbox" until we finish with the first one.
      receive do { ^pid, result } -> result end
    end)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule ParallelMapTest do
    use ExUnit.Case, async: true

    test "parallel map of numbers" do
      assert Parallel.pmap(1..50, fn(integer) -> integer * integer end) == [1,4,9,16,25,36,49,64,81,100,121,144,169,
        196,225,256,289,324,361,400,441,484,529,576,625,676,729,784,841,900,961,1024,1089,1156,1225,1296,1369,1444,
        1521,1600,1681,1764,1849,1936,2025,2116,2209,2304,2401,2500]
    end

  end
end
