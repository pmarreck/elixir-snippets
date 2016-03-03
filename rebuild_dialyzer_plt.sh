# this is based on information in episode 125 of ElixirSips
dialyzer --build_plt --apps erts $(elixir -e 'IO.write :code.lib_dir(:elixir)')/ebin
