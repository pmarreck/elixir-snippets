defmodule FactorialWithoutTCORecursion do
  def of(0), do: 1
  def of(n) when n > 0 do
    n * of(n - 1)
  end
end

defmodule FactorialWithTCORecursion do
  def of(n), do: of(1, n)
  def of(fact, 0), do: fact
  def of(fact, n) when n > 0 do
    of(fact * n, n-1)
  end
end

