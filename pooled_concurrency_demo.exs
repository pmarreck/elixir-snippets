# pooled concurrency demo

# At this time, the work chosen to demo this (factorial) is not effective,
# because after distributing the work and getting the answers back (at least
# for a very big number), the main core still has to multiply all the answers,
# taking 90% of the time, blocking on 1 core. :O
# Still, it was a great learning exercise, and I am going to hack on it
# for a bit to see if I can't get a better demo out of it, and make
# the code better/cleaner.

# As you can see I like dependency injection for unit testing, but Elixir
# doesn't make this the cleanest thing (yet)... I will be trying to improve
# that too, as the readability here takes a hit.

defmodule ConcurrencyDemo do

  defmodule IONoop do
    def puts(_) do
    end
  end
  @debug IONoop #IO

  def num_procs(erlang \\ :erlang) do
    erlang.system_info(:logical_processors)
  end

  def query_node(nodename, func, node \\ Node) do
    me = self
    pid = node.spawn(nodename, fn -> (send me, { self, func.() }) end)
    receive do {^pid, result} -> result end
  end

  def machines(node \\ Node) do
    node.list(:known)
  end

  def num_total_workers_by_machine(machines \\ machines, erlang \\ :erlang) do
    machines |> Enum.map(fn nodename ->
      {nodename, query_node(nodename, fn ->
        erlang.system_info(:logical_processors)
      end)}
    end)
  end

  def num_total_workers(num_total_workers_by_machine \\ num_total_workers_by_machine) do
    num_total_workers_by_machine |> Enum.reduce(0, fn({_, procs},tot) -> tot + procs end)
  end

  def worker_pool_by_nodenames(num_total_workers_by_machine \\ num_total_workers_by_machine) do
    num_total_workers_by_machine |> Enum.flat_map(fn {w,procs} -> List.duplicate(w,procs) end)
  end

  def split_range_of_numbers(%Range{first: start, last: finish}, approx_chunk_size \\ 150) do
    size = (finish - start)
    if size < approx_chunk_size do
      [start..finish]
    else
      halfway = trunc(start + (size/2))
      List.flatten [split_range_of_numbers(start..halfway, approx_chunk_size), split_range_of_numbers((halfway+1)..finish, approx_chunk_size)]
    end
  end

  # Allows mapping over a work collection using any nodes available
  def pmap(collection, func, worker_pool_by_nodenames \\ worker_pool_by_nodenames, node \\ Node) do
    # Get this process's PID
    me = self
    @debug.puts "Collection length is: #{length(collection)}"
    collection
    # First, assign a machine to receive each sub-workload
    |> Enum.zip(Stream.cycle(worker_pool_by_nodenames))
    |> Enum.map(fn {elem, machine_name} ->
      # For each element in the collection, spawn a process on machine_name and
      # tell it to:
      # - Run the given function on that element
      # - Call up the parent process
      # - Send the parent its PID and its result
      # Each call to spawn_link returns the child PID immediately.
      @debug.puts "I am spawning a worker on #{machine_name} for range: #{inspect elem}"
      node.spawn_link machine_name, fn -> (send me, { self, func.(elem) }) end
    end)
    # Here we have the complete list of child PIDs. We don't yet know
    # which, if any, have completed their work
    |> Enum.map(fn (pid) ->
      @debug.puts "I am waiting on results from pid #{inspect pid}"
      # For each child PID, in order, block until we receive an
      # answer from that PID and return the answer
      # While we're waiting on something from the first pid, we may
      # get results from others, but we won't "get those out of the
      # mailbox" until we finish with the first one.
      receive do { ^pid, result } -> (@debug.puts "I got result #{result} from pid #{inspect pid}"; result) end
    end)
  end


  # bodyless signature with defaults
  def concurrent_factorial(range, worker_pool_by_nodenames \\ worker_pool_by_nodenames, node \\ Node, chunk_size \\ nil)

  def concurrent_factorial(range = %Range{first: start, last: finish}, worker_pool_by_nodenames, node, chunk_size) do
    unless chunk_size do
      # split up the work into roughly equal ranges times the number of total cores available
      chunk_size = (finish - start)/length(worker_pool_by_nodenames)
    end
    @debug.puts "Worker pool length is: #{length(worker_pool_by_nodenames)}."
    @debug.puts "I have a range from #{start} to #{finish}. chunk_size is #{chunk_size}."
    work_chunks = split_range_of_numbers(range, chunk_size)
    @debug.puts "Number of work chunks are: #{length(work_chunks)}. Pmapping"
    pmap(work_chunks,
      fn(subrange) -> subrange |> Enum.reduce(&(&1*&2)) end,
      worker_pool_by_nodenames,
      node
    )
    # one more reduction... WHICH, WHOOPS, TAKES THE LONGEST TIME OF ALL on big ranges.
    # Like 90% of the time. Blocking 1 core.
    # Making most of this parallelization useless for this algorithm...
    # but it was a learning experience! ::slaps forehead::
    |> Enum.reduce(&(&1*&2))
  end

  def concurrent_factorial(n, worker_pool_by_nodenames, node, chunk_size) when is_integer(n) and n > 0 do
    concurrent_factorial(1..n, worker_pool_by_nodenames, node, chunk_size)
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule ConcurrencyDemoTest do
    use ExUnit.Case, async: true
    alias ConcurrencyDemo, as: T
    @tag timeout: 90000

    defmodule ErlangSystemInfoStub do
      def system_info(:logical_processors), do: 64 # one day...
    end

    defmodule NodeStub do
      # simulates self-named node
      def self, do: :"zombie@nation"
      # simulates remote spawn, just does it locally
      def spawn(_, func) do
        # IO.puts "I am spawning"
        Kernel.spawn(func)
      end
      def spawn_link(_, func) do
        # IO.puts "I am spawn_linking"
        Kernel.spawn_link(func)
      end
      def list, do: []
      def list(:known), do: [:"zombie@nation"]
    end

    @num_cores_on_this_machine :erlang.system_info(:logical_processors)

    defp stubbed_worker_pool_by_nodenames do
      List.duplicate(:"zombie@nation", @num_cores_on_this_machine)
    end

    test "num_procs" do
      assert T.num_procs > 0
    end

    test "query node" do
      assert T.query_node(NodeStub.self, fn -> :erlang.system_info(:logical_processors) end, NodeStub) == @num_cores_on_this_machine
    end

    test "machines length at least 1" do
      assert length(T.machines(NodeStub)) == 1
    end

    test "num_total_workers_by_machine" do
      assert T.num_total_workers_by_machine([Node.self], ErlangSystemInfoStub) == [{Node.self, 64}]
    end

    test "num_total_workers" do
      assert T.num_total_workers([{:"zombie@nation", 64},{:"this@that", 64} ]) == 128
    end

    test "worker_pool_by_nodenames" do
      assert T.worker_pool_by_nodenames([{:"a@b",2},{:"c@d",2}]) == [:"a@b",:"a@b",:"c@d",:"c@d"]
    end

    test "split_range_of_numbers" do
      assert T.split_range_of_numbers(1..100, 50) == [1..50,51..100]
      assert T.split_range_of_numbers(1..50, 50) == [1..50]
    end

    test "pmap" do
      assert T.pmap([1,2,3], &(&1), [:"zombie@nation"], NodeStub) == [1,2,3]
    end

    test "concurrent_factorial_n" do
      assert T.concurrent_factorial(10) == 3628800
      assert T.concurrent_factorial(10, stubbed_worker_pool_by_nodenames, NodeStub, 3) == 3628800
      # The following spends all its time in the recombination of results step. LOL
      # assert T.concurrent_factorial(1000000, stubbed_worker_pool_by_nodenames, NodeStub, 200000) == 'whatevs, just testing core flooding'
    end

  end
end

