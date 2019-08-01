# Did you know that regular functions can take do-blocks?
# They are evaluated when they're passed in, though
# (unlike Ruby!)

defmodule DoWhat do
  def take_a_do(kwl) do
    the_do = kwl[:do]
    IO.inspect the_do
  end
end

DoWhat.take_a_do do
  IO.puts "Now"
  "what is the meaning"
end
