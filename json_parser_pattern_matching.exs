Code.require_file "single_file_app_logger.exs" # will be discarded if this gets promoted to a first-class Mix project

defmodule TheOneTrueJSON do
  @moduledoc """
  A feeble attempt at a cheap JSON to Elixir data structure parser which utilizes pattern-matching extensively.
  I intentionally used NO regex, to get some exercise with the pattern-matching capabilities of Elixir/Erlang.
  String keys in objects become atoms, for now. See below. I was going to add a switch for this.
  Also, don't use this for production work. Use Poison https://github.com/devinus/poison
  I just did this as an exercise/proof-of-concept, mainly.
  """
  alias TheOneTrueJSON, as: JSON
  use SingleFileAppLogger # will be discarded/refactored if this gets promoted to a first-class Mix project

  # just for reference mainly
  @contexts { :string, :number, :decimal, :exponent, :array, :object, :pair, :key, :value, :boolean, :comma_or_close_array, :comma_or_close_object }
  @whitespace '\s\n\t\r'
  @digits ?0..?9
  @number_start [?- | (@digits |> Enum.to_list)]

  @doc """
  The entry point. A "value" is expected, so that context is pushed onto the stack.
  """
  def parse(json_string) do
    debug "Starting json parse of string: " <> json_string
    parse(json_string, [:value], "")
  end

  @doc """
  The empty string case.
  """
  def parse("", [:value], "") do
    debug "Empty string"
    {:ok, nil}
  end
  @doc """
  The finished case. Nothing left to parse, context is root, output has content.
  """
  def parse("", [], output) when is_binary(output) do
    debug "Finishing json parse, output string: #{output}"
    {val, _} = Code.eval_string(output)
    {:ok, val}
  end

  @doc """
  Pass through whitespace in a string context.
  """
  def parse(<<s::utf8, t::binary>>, context = [:string | _], output) when s in @whitespace do
    debug "Passing through empty space inside a string."
    parse(t, context, output <> <<s>>)
  end

  @doc """
  Skip whitespace outside a string context.
  """
  def parse(<<s::utf8, t::binary>>, context, output) when s in @whitespace do
    debug "Skipping whitespace outside a string context."
    parse(t, context, output)
  end

  @doc """
  Naked boolean true, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?t, ?r, ?u, ?e, t::binary>>, [:value | context], output) do
    output = output <> "true"
    debug "Matched boolean 'true'.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Naked boolean false, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?f, ?a, ?l, ?s, ?e, t::binary>>, [:value | context], output) do
    output = output <> "false"
    debug "Matched boolean 'false'.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Naked null, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?n, ?u, ?l, ?l, t::binary>>, [:value | context], output) do
    output = output <> "nil"
    debug "Matched null/nil.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Boolean true, inside an array context. Expect comma or close array.
  """
  def parse(<<?t, ?r, ?u, ?e, t::binary>>, context = [:array | _], output) do
    context = [:comma_or_close_array | context]
    output = output <> "true"
    debug "Matched boolean 'true' inside an array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Boolean false, inside an array context. Expect comma or close array.
  """
  def parse(<<?f, ?a, ?l, ?s, ?e, t::binary>>, context = [:array | _], output) do
    context = [:comma_or_close_array | context]
    output = output <> "false"
    debug "Matched boolean 'false' inside an array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Null, inside an array context. Expect comma or close array.
  """
  def parse(<<?n, ?u, ?l, ?l, t::binary>>, context = [:array | _], output) do
    context = [:comma_or_close_array | context]
    output = output <> "nil"
    debug "Matched null/nil inside an array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Arrays, when a value is expected. If it matches, push that context.
  """
  def parse(<<?[, t::binary>>, [:value | context], output) do
    context = [:array | context]
    output = output <> <<?[>>
    debug "Started an array context when a value was expected.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Closing arrays, when a comma or close array is expected. If it matches, pop that context.
  """
  def parse(<<?], t::binary>>, [:comma_or_close_array, :array | context], output) do
    output = output <> <<?]>>
    debug "Closed an array context when a value wasn't expected", t, context, output
    parse(t, context, output)
  end

  @doc """
  Closing arrays, when a value is not expected. If it matches, pop that context.
  """
  def parse(<<?], t::binary>>, [:array | context], output) do
    output = output <> <<?]>>
    debug "Closed an array context when a value wasn't expected.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Commas in arrays, outside a value, when a comma or close array is expected. If it matches, expect another value.
  """
  def parse(<<?,, t::binary>>, [:comma_or_close_array, :array | context], output) do
    context = [:value, :array | context]
    output = output <> <<?,>>
    debug "Found a comma in an array, now expecting a value.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Commas in objects, outside a value. If it matches, expect another pair key.
  """
  def parse(<<?,, t::binary>>, context = [:object | _], output) do
    context = [:key, :pair | context]
    output = output <> <<?},?,,?{>>
    debug "Found a comma in an object, now expecting a value.", t, context, output
    parse(t, context, output)
  end
  @doc """
  String key in object when pair key expected
  """
  def parse(<<?", t::binary>>, context = [:key, :pair, :object | _], output) do
    context = [:string | context]
    output = output <> <<?:, ?">>
    debug "Found a string key in object when a value was expected, starting string key object context.", t, context, output
    parse(t, context, output)
  end
  @doc """
  Strings, when a value is expected. Start a string context.
  """
  def parse(<<?", t::binary>>, [:value | context], output) do
    context = [:string | context]
    output = output <> <<?">>
    debug "Found a string when a value was expected, starting string context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Strings, inside an array. Start a string context.
  """
  def parse(<<?", t::binary>>, context = [:array | _], output) do
    context = [:string | context]
    output = output <> <<?">>
    debug "Found a string inside an array, starting string context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Pass through escaped string terminators in a string context.
  """
  def parse(<<?\\, ?", t::binary>>, context = [:string | _], output) do
    output = output <> <<?\\, ?">>
    debug "Found escaped double quote in a string context, passing through.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop spaces encountered after end of key (while waiting for colon) in object key context.
  """
  def parse(<<?", s, t::binary>>, context = [:string, :key, :pair, :object | _], output) when s in @whitespace do
    t = <<?">> <> t
    debug "Dropping space after end of string key in object context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  End string encountered in object key context. Expect value.
  """
  def parse(<<?", ?:, t::binary>>, [:string, :key, :pair, :object | context], output) do
    context = [:value, :object | context]
    output = output <> <<?", ?,>>
    debug "Found end of string key in object context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  End a string context if a string terminator inside an array is reached,
  then expect a comma or close-array.
  """
  def parse(<<?", t::binary>>, [:string, :array | context], output) do
    context = [:comma_or_close_array, :array | context]
    output = output <> <<?">>
    debug "Found close quote in a string context inside an array, passing through while expecting a comma or close-array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  End a string context if a string terminator is reached.
  """
  def parse(<<?", t::binary>>, [:string | context], output) do
    output = output <> <<?">>
    debug "Found close quote in a string context, popping string context and passing through quote.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Pass through any characters that are not a string terminator in a string context.
  Have to be careful dealing with utf8 here...
  """
  def parse(<<char::utf8, t::binary>>, context = [:string | _], output) do
    output = output <> <<char::utf8>>
    debug "Passing through this character in a string context: #{<<char::utf8>>}.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Digits during a number context.
  """
  def parse(<<n::utf8, t::binary>>, context = [:number | _], output) when n in @digits do
    output = output <> <<n>>
    debug "Found digit in number context: #{<<n>>}.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Digits, when a value is expected. Sets number context.
  """
  def parse(<<n::utf8, t::binary>>, [:value | context], output) when n in @number_start do
    context = [:number | context]
    output = output <> <<n>>
    debug "Found digit while value expected: #{<<n>>}.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Digits in a bare array. Sets number context.
  """
  def parse(<<n::utf8, t::binary>>, context = [:array | _], output) when n in @number_start do
    context = [:number | context]
    output = output <> <<n>>
    debug "Found digit while in array: #{<<n>>}.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by + during a number context. Drops the +.
  """
  def parse(<<?e, ?+, t::binary>>, context = [:number | _], output) do
    t = <<?e>> <> t
    debug "Found exponent plus during a number context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by - followed by a digit during a number context.
  Pushes an extra float onto the output for Elixir's sake.
  """
  def parse(<<?e, ?-, n::utf8, t::binary>>, [:number | context], output) when n in @digits do
    context = [:exponent | context]
    output = output <> <<?., ?0, ?e, ?-, n>>
    debug "Found exponent minus number during a number context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by a digit during a number context. Pushes an extra float onto the output for Elixir's sake.
  """
  def parse(<<?e, n::utf8, t::binary>>, [:number | context], output) when n in @digits do
    context = [:exponent | context]
    output = output <> <<?., ?0, ?e, n>>
    debug "Found exponent during a number context.", t, context, output
    parse(t, context, output)
  end

  # short circuit capital E exponent in a number context
  def parse(<<?E, t::binary>>, context = [:number | _], output) do
    parse(<<?e>> <> t, context, output)
  end

  @doc """
  Decimal during a number context. Pushes decimal context.
  """
  def parse(<<?., n::utf8, t::binary>>, context = [:number | _], output) when n in @digits do
    context = [:decimal | context]
    output = output <> <<?., n>>
    debug "Found decimal and digit #{<<n>>} during a number context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Digits during a decimal context.
  """
  def parse(<<n::utf8, t::binary>>, context = [:decimal | _], output) when n in @digits do
    output = output <> <<n>>
    debug "Found digit #{<<n>>} during a decimal context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by + during a decimal context. Drops the +.
  """
  def parse(<<?e, ?+, t::binary>>, context = [:decimal | _], output) do
    t = <<?e>> <> t
    debug "Found exponent and + during a decimal context, dropping +.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by - followed by a digit during a decimal context.
  """
  def parse(<<?e, ?-, n, t::binary>>, [:decimal | context], output) when n in @digits do
    context = [:exponent | context]
    output = output <> <<?e, ?-, n>>
    debug "Found exponent and - and digit #{<<n>>} during a decimal context, dropping decimal context and adding exponent context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Exponent followed by a digit during a decimal context.
  """
  def parse(<<?e, n, t::binary>>, [:decimal | context], output) when n in @digits do
    context = [:exponent | context]
    output = output <> <<?e, n>>
    debug "Found exponent and digit #{<<n>>} during a decimal context, dropping decimal context and adding exponent context.", t, context, output
    parse(t, context, output)
  end

  # short circuit capital E exponent in a decimal context
  def parse(<<?E, t::binary>>, context = [:decimal | _], output) do
    parse(<<?e>> <> t, context, output)
  end

  @doc """
  Digits during an exponent context.
  """
  def parse(<<n::utf8, t::binary>>, context = [:exponent | _], output) when n in @digits do
    output = output <> <<n>>
    debug "Found digit during exponent context: #{<<n>>}.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop exponent context if no more digits.
  """
  def parse(<<n::utf8, t::binary>>, [:exponent | context], output) when not n in @digits do
    t = <<n>> <> t
    debug "Dropping exponent context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop exponent context if no more input.
  """
  def parse("", [:exponent | context], output) do
    debug "Dropping exponent context- no more input."
    parse("", context, output)
  end

  @doc """
  Drop decimal context if no more digits UNLESS it is another decimal,
  in which case it shouldn't parse.
  """
  def parse(<<n::utf8, t::binary>>, [:decimal | context], output) when (not n in @digits) and (n != ?.) do
    t = <<n>> <> t
    debug "Dropping decimal context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop decimal context if no more input.
  """
  def parse("", [:decimal | context], output) do
    debug "Dropping decimal context- no more input."
    parse("", context, output)
  end

  @doc """
  Drop number context if no more digits inside an array, then expect comma_or_close_array.
  """
  def parse(<<n::utf8, t::binary>>, [:number, :array | context], output) when not n in @digits do
    t = <<n>> <> t
    context = [:comma_or_close_array, :array | context]
    debug "Dropping number context and expecting comma or end-array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop number context if no more digits.
  """
  def parse(<<n::utf8, t::binary>>, [:number | context], output) when not n in @digits do
    t = <<n>> <> t
    debug "Dropping number context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop number context if no more input.
  """
  def parse("", [:number | context], output) do
    debug "Dropping number context- no more input.", "", context, output
    parse("", context, output)
  end

  @doc """
  Drop spaces after an object start when value expected.
  """
  def parse(<<?{, n::utf8, t::binary>>, context = [:value | _], output) when n in @whitespace do
    t = <<?{, t::binary>>
    debug "Dropping whitespace after object start when value expected.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Drop spaces after an object start in an array context.
  """
  def parse(<<?{, n::utf8, t::binary>>, context = [:array | _], output) when n in @whitespace do
    t = <<?{, t::binary>>
    debug "Dropping whitespace after object start in array context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Empty object when value expected. Drop value expectation.
  """
  def parse(<<?{, ?}, t::binary>>, [:value | context], output) do
    output = output <> <<?[, ?{, ?}, ?]>>
    debug "Found empty object when value expected. Passing through and dropping value expectation."
    parse(t, context, output)
  end

  @doc """
  Object opener and key start/quote when value expected. Push string, key, pair, object context.
  NOTE: This will create atoms from string keys. Perhaps that's a DDoS attack vector (see: Ruby symbols)?
        Maybe add a switch/mode later.
  """
  def parse(<<?{, ?", t::binary>>, [:value | context], output) do
    context = [:string, :key, :pair, :object | context]
    output = output <> <<?[, ?{, ?:, ?">>
    debug "Found object start and string key start when value expected. Pushing string, key, pair, object context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Empty object encountered inside an array context. Expect comma_or_close_array.
  """
  def parse(<<?{, ?}, t::binary>>, context = [:array | _], output) do
    context = [:comma_or_close_array | context]
    output = output <> <<?[, ?{, ?}, ?]>>
    debug "Found empty object when inside array. Expecting comma or close array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Object opener and key start/quote encountered inside an array context. Push string, key, pair, object context.
  """
  def parse(<<?{, ?", t::binary>>, context = [:array | _], output) do
    context = [:string, :key, :pair, :object | context]
    output = output <> <<?[, ?{, ?:, ?">>
    debug "Found object start and string key start when inside array. Pushing string, key, pair, object context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Object close character. Pop any existing pair context.
  """
  def parse(<<?}, t::binary>>, [:pair, :object | context], output) do
    t = <<?}>> <> t
    context = [:object | context]
    debug "Closing pair context.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Object close character in object, array context. Pop object context, expect comma_or_close_array.
  """
  def parse(<<?}, t::binary>>, [:object, :array | context], output) do
    context = [:comma_or_close_array, :array | context]
    output = output <> <<?},?]>>
    debug "Closing object context in array and expecting comma_or_close_array.", t, context, output
    parse(t, context, output)
  end

  @doc """
  Object close character. Pop object context.
  """
  def parse(<<?}, t::binary>>, [:object | context], output) do
    output = output <> <<?},?]>>
    debug "Closing object context.", t, context, output
    parse(t, context, output)
  end


  # fallthrough... problem?
  def parse(json_string, context, output) do
    err = "WARNING: JSON string not parseable."
    debug err, json_string, context, output
    {:error, err}
  end

  # defp debug(_, _ \\ "", _ \\ [], _ \\ "") do
  #   :ok
  # end

  defp debug(_msg, _json \\ nil, _context \\ nil, _output \\ nil) do
    Logger.debug fn ->
      msg = _msg
      if _json,    do: msg = msg <> "\n json:    " <> String.slice(_json, 0..9)
      if _context, do: msg = msg <> "\n context: " <> inspect(_context)
      if _output,  do: msg = msg <> "\n output:  " <> String.slice(_output, -10..-1)
      msg
    end
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
# If you want debug output, use "ELIXIR_LOGLEVEL=debug elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule Time do
    def now do
      {mega, s, micro} = :erlang.now
      (mega * 1000000) + s + (micro / 1000000)
    end
  end
  defmodule JsonTest do
    use ExUnit.Case, async: true

    alias TheOneTrueJSON, as: JSON

    @huge_json """
[
    {
        "description": "allOf",
        "schema": {
            "allOf": [
                {
                    "properties": {
                        "bar": {"type": "integer"}
                    },
                    "required": ["bar"]
                },
                {
                    "properties": {
                        "foo": {"type": "string"}
                    },
                    "required": ["foo"]
                }
            ]
        },
        "tests": [
            {
                "description": "allOf",
                "data": {"foo": "baz", "bar": 2},
                "valid": true
            },
            {
                "description": "mismatch second",
                "data": {"foo": "baz"},
                "valid": false
            },
            {
                "description": "mismatch first",
                "data": {"bar": 2},
                "valid": false
            },
            {
                "description": "wrong type",
                "data": {"foo": "baz", "bar": "quux"},
                "valid": false
            }
        ]
    },
    {
        "description": "allOf with base schema",
        "schema": {
            "properties": {"bar": {"type": "integer"}},
            "required": ["bar"],
            "allOf" : [
                {
                    "properties": {
                        "foo": {"type": "string"}
                    },
                    "required": ["foo"]
                },
                {
                    "properties": {
                        "baz": {"type": "null"}
                    },
                    "required": ["baz"]
                }
            ]
        },
        "tests": [
            {
                "description": "valid",
                "data": {"foo": "quux", "bar": 2.0, "baz": null},
                "valid": true
            },
            {
                "description": "mismatch base schema",
                "data": {"foo": "quux", "baz": null},
                "valid": false
            },
            {
                "description": "mismatch first allOf",
                "data": {"bar": 2.5e3, "baz": null},
                "valid": false
            },
            {
                "description": "mismatch second allOf",
                "data": {"foo": "quux", "bar": 2},
                "valid": false
            },
            {
                "description": "mismatch both",
                "data": {"bar": 2},
                "valid": false
            }
        ]
    },
    {
        "description": "allOf simple types",
        "schema": {
            "allOf": [
                {"maximum": 30},
                {"minimum": 20}
            ]
        },
        "tests": [
            {
                "description": "valid",
                "data": 25,
                "valid": true
            },
            {
                "description": "mismatch one",
                "data": 35,
                "valid": false
            }
        ]
    }
]
    """

    #### success assertions

    test "json parsing empty string" do
      assert {:ok, nil} == JSON.parse("")
    end

    test "json parsing naked booleans" do
      assert {:ok, true}  == JSON.parse("true")
      assert {:ok, false} == JSON.parse("false")
      assert {:ok, nil}   == JSON.parse("null")
    end

    test "json parsing naked booleans leading space" do
      assert {:ok, true}  == JSON.parse("  true")
      assert {:ok, false} == JSON.parse("  false")
      assert {:ok, nil}   == JSON.parse("  null")
    end

    test "json parsing naked booleans trailing space" do
      assert {:ok, true}  == JSON.parse("true  ")
      assert {:ok, false} == JSON.parse("false  ")
      assert {:ok, nil}   == JSON.parse("null  ")
    end

    test "json parsing scattered space in an array context" do
      assert {:ok, []} == JSON.parse(" [ ] ")
    end

    test "json parsing arrays of booleans" do
      assert {:ok, [true, false]} == JSON.parse("[ true, false] ")
    end

    test "json parsing nested arrays of booleans" do
      assert {:ok, [true, [true, false]]} == JSON.parse("[ true , [true, false] ] ")
    end

    test "json parsing strings" do
      assert {:ok, "behold"} == JSON.parse("\"behold\"")
    end

    test "json parsing strings with escaped string-end character" do
      assert {:ok, "beh\"old"} == JSON.parse("\"beh\\\"old\"")
    end

    test "json parsing string with space and boolean in array" do
      assert {:ok, ["behold ", true]} == JSON.parse("[\"behold \", true ]")
    end

    test "json parsing simple number" do
      assert {:ok, 2256} == JSON.parse("2256")
    end

    test "json parsing negative number" do
      assert {:ok, -2256} == JSON.parse("-2256")
    end

    test "json parsing simple number in array" do
      assert {:ok, [2256]} == JSON.parse("[2256]")
    end

    test "json parsing decimal" do
      assert {:ok, 2256.93} == JSON.parse("2256.93")
    end

    test "json parsing decimals in array" do
      assert {:ok, [123.45, 67.809]} == JSON.parse("[123.45, 67.809]")
    end

    test "json parsing number with immediate exponent" do
      assert {:ok, 1.0e6} == JSON.parse("10e5")
    end

    test "json parsing float with exponent" do
      assert {:ok, 1.0e6} == JSON.parse("10.0e5")
    end

    test "json parsing float with positive exponent" do
      assert {:ok, 1.0e6} == JSON.parse("10.0e+5")
    end

    test "json parsing float with negative exponent" do
      assert {:ok, 0.0001} == JSON.parse("10.0e-5")
    end

    test "json parsing array with floats and lf's" do
      assert {:ok, [214.75, 18.23]} == JSON.parse(" [214.75,\n 18.23]")
    end

    test "json parsing array with floats and cr's" do
      assert {:ok, [214.75, 18.23]} == JSON.parse(" [214.75,\r 18.23\r]")
    end

    test "json parsing array with floats and crlf's" do
      assert {:ok, [214.75, 18.23]} == JSON.parse(" [\r\n214.75,\r\n 18.23]")
    end

    test "json parsing simple object" do
      assert {:ok, [a: 5, b: "6"]} == JSON.parse("{\"a\": 5, \"b\": \"6\"}")
    end

    test "json parsing complex nested object" do
      assert {:ok, [a: [-256.3, "this is\" a test", [d: 25]], b: ["yabba", 0xdabba, "doo"], c: nil]} == JSON.parse("{\"a\":[-256.3,\"this is\\\" a test\",{\"d\":25}], \"b\":[\"yabba\",895930,\"doo\"],\"c\":null}")
    end

    test "json parsing empty object" do
      assert {:ok, [{}]} == JSON.parse("{}")
    end

    test "json parsing object with spaces between key colon and value" do
      assert {:ok, [a: 5]} == JSON.parse("{\"a\"  : 5}")
    end

    test "doesn't choke on unicode in strings" do
      assert {:ok, "üntergliebenglauténgloben"} == JSON.parse("\"üntergliebenglauténgloben\"")
    end

    @tag timeout: 100000
    test "json parsing really hairy json" do
      assert {:ok, _} = JSON.parse(@huge_json)
      # now time it
      json_length = String.length @huge_json
      times = 100
      t = Time.now
      for _ <- 0..times do
        JSON.parse(@huge_json)
      end
      t_end = Time.now
      IO.puts ""
      IO.puts "Time to parse huge json #{times} times: #{t_end - t}"
      IO.puts "Number of characters in huge json: #{json_length}"
      IO.puts "JSON chars processed/sec: #{(json_length * times)/(t_end - t)}"
    end

    #### error assertions

    test "malformed number" do
      assert {:error, _} = JSON.parse("243y82")
    end

    test "malformed decimal" do
      assert {:error, _} = JSON.parse("123.45.67")
    end

    test "missing decimal" do
      assert {:error, _} = JSON.parse("123.")
    end

    test "malformed exponent" do
      assert {:error, _} = JSON.parse("123eyman")
      assert {:error, _} = JSON.parse("123e45.23")
    end

    test "missing exponent" do
      assert {:error, _} = JSON.parse("123e")
    end

    test "unterminated string in array" do
      assert {:error, _} = JSON.parse("[\"whoops]")
    end

    test "unclosed object" do
      assert {:error, _} = JSON.parse("[5, \"a\", {]")
    end

    test "overly closed object" do
      assert {:error, _} =  JSON.parse("{{}}}")
    end

    test "unclosed array" do
      assert {:error, _} = JSON.parse("[[[[[true]]]]")
    end

    test "overly closed array" do
      assert {:error, _} = JSON.parse("[[[[]]]]]")
    end

    test "object with no value" do
      assert {:error, _} = JSON.parse("{\"a\": }")
    end

    test "object with no key" do
      assert {:error, _} = JSON.parse("{\"a\"}")
      assert {:error, _} = JSON.parse("{5}")
    end

    test "object with wrong key type" do
      assert {:error, _} = JSON.parse("{65: 23}")
    end

    test "object with wrong string key delimiter" do
      assert {:error, _} = JSON.parse("{'65': 23}")
    end

    test "consecutive booleans in array, no comma" do
      assert {:error, _} = JSON.parse("[true false]")
    end

    test "comma at start of array" do
      assert {:error, _} = JSON.parse("[,true]")
    end

    test "comma at end of array" do
      assert {:error, _} = JSON.parse("[false,]")
    end

    test "comma at start of object" do
      assert {:error, _} = JSON.parse("{,\"b\":true}")
    end

    test "comma at end of object" do
      assert {:error, _} = JSON.parse("{\"a\":false,}")
    end

  end
end
