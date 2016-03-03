dialyzer --build_plt --apps erts $(elixir -e 'IO.write :code.lib_dir(:elixir)')/ebin
