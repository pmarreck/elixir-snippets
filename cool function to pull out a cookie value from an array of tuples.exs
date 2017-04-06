 defmodule Cookie do
   def run([ { "Set-Cookie", _} | [{"Set-Cookie", val} | _] ]), do: val
   def run([ { "Set-Cookie", _} | _ ]), do: return
   def run([ _ | rest ]), do: run(rest)
 end