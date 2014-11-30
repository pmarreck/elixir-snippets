# defmodule Foo do
#   def check_fn(func) do
#     # (fn p -> p + 1 end) = func
#   end
# end

# Foo.check_fn(fn p -> p + 1 end)

add1 = fn p -> p + 1 end
add2 = fn p -> p + 2 end

^add1 = add1

# ^add2 = add1

IO.inspect :erlang.fun_info(add1)
IO.inspect add2
