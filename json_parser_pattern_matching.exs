defmodule TheOneTrueJSON do
  @moduledoc """
  A feeble attempt at a cheap JSON to Elixir data structure parser which utilizes pattern-matching extensively.
  String keys in objects become atoms, for now. See below.
  """
  alias TheOneTrueJSON, as: JSON

  # just for reference mainly
  @contexts { :string, :number, :decimal, :exponent, :array, :object, :pair, :key, :value, :boolean, :comma_or_close_array, :comma_or_close_object }
  @whitespace '\s\n\t\r'
  @number_start '-0123456789'
  @digits ?0..?9

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
  def parse(<<s, t::binary>>, context = [:string | _], output) when s in @whitespace do
    debug "Passing through empty space inside a string"
    parse(t, context, output <> <<s>>)
  end

  @doc """
  Skip whitespace outside a string context.
  """
  def parse(<<s, t::binary>>, context, output) when s in @whitespace do
    debug "Skipping whitespace outside a string context"
    parse(t, context, output)
  end

  @doc """
  Naked boolean true, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?t, ?r, ?u, ?e, t::binary>>, [:value | context], output) do
    debug "Matched boolean 'true'", t, context, output
    parse(t, context, output <> "true")
  end

  @doc """
  Naked boolean false, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?f, ?a, ?l, ?s, ?e, t::binary>>, [:value | context], output) do
    debug "Matched boolean 'false'", t, context, output
    parse(t, context, output <> "false")
  end

  @doc """
  Naked null, when a value is expected. If it matches, pop that context.
  """
  def parse(<<?n, ?u, ?l, ?l, t::binary>>, [:value | context], output) do
    debug "Matched null/nil", t, context, output
    parse(t, context, output <> "nil")
  end

  @doc """
  Boolean true, inside an array context. Expect comma or close array.
  """
  def parse(<<?t, ?r, ?u, ?e, t::binary>>, c = [:array | context], output) do
    debug "Matched boolean 'true' inside an array", t, context, output
    parse(t, [:comma_or_close_array | c], output <> "true")
  end

  @doc """
  Boolean false, inside an array context. Expect comma or close array.
  """
  def parse(<<?f, ?a, ?l, ?s, ?e, t::binary>>, c = [:array | context], output) do
    debug "Matched boolean 'false' inside an array", t, context, output
    parse(t, [:comma_or_close_array | c], output <> "false")
  end

  @doc """
  Null, inside an array context. Expect comma or close array.
  """
  def parse(<<?n, ?u, ?l, ?l, t::binary>>, c = [:array | context], output) do
    debug "Matched null/nil inside an array", t, context, output
    parse(t, [:comma_or_close_array | c], output <> "nil")
  end

  @doc """
  Arrays, when a value is expected. If it matches, push that context.
  """
  def parse(<<?[, t::binary>>, [:value | context], output) do
    debug "Started an array context when a value was expected", t, context, output
    parse(t, [:array | context], output <> <<?[>>)
  end

  @doc """
  Closing arrays, when a comma or close array is expected. If it matches, pop that context.
  """
  def parse(<<?], t::binary>>, [:comma_or_close_array, :array | context], output) do
    debug "Closed an array context when a value wasn't expected", t, context, output
    parse(t, context, output <> <<?]>>)
  end

  @doc """
  Closing arrays, when a value is not expected. If it matches, pop that context.
  """
  def parse(<<?], t::binary>>, [:array | context], output) do
    debug "Closed an array context when a value wasn't expected", t, context, output
    parse(t, context, output <> <<?]>>)
  end

  @doc """
  Commas in arrays, outside a value, when a comma or close array is expected. If it matches, expect another value.
  """
  def parse(<<?,, t::binary>>, [:comma_or_close_array, :array | context], output) do
    debug "Found a comma in an array, now expecting a value", t, context, output
    parse(t, [:value, :array | context], output <> <<?,>>)
  end

  @doc """
  Commas in objects, outside a value. If it matches, expect another pair key.
  """
  def parse(<<?,, t::binary>>, c = [:object | context], output) do
    debug "Found a comma in an object, now expecting a value", t, context, output
    parse(t, [:key, :pair | c], output <> <<?},?,,?{>>)
  end
  @doc """
  String key in object when pair key expected
  """
  def parse(<<?", t::binary>>, c = [:key, :pair, :object | context], output) do
    debug "Found a string key in object when a value was expected, starting string key object context", t, context, output
    parse(t, [:string | c], output <> <<?:, ?">>)
  end
  @doc """
  Strings, when a value is expected. Start a string context.
  """
  def parse(<<?", t::binary>>, [:value | context], output) do
    debug "Found a string when a value was expected, starting string context", t, context, output
    parse(t, [:string | context], output <> <<?">>)
  end

  @doc """
  Strings, inside an array. Start a string context.
  """
  def parse(<<?", t::binary>>, c = [:array | context], output) do
    debug "Found a string inside an array, starting string context", t, context, output
    parse(t, [:string | c], output <> <<?">>)
  end

  @doc """
  Pass through escaped string terminators in a string context.
  """
  def parse(<<?\\, ?", t::binary>>, c = [:string | context], output) do
    debug "Found escaped double quote in a string context, passing through", t, context, output
    parse(t, c, output <> <<?\\, ?">>)
  end

  @doc """
  Drop spaces encountered after end of key (while waiting for colon) in object key context.
  """
  def parse(<<?", s, t::binary>>, c = [:string, :key, :pair, :object | context], output) when s in @whitespace do
    debug "Dropping space after end of string key in object context", t, context, output
    parse(<<?">> <> t, c, output)
  end

  @doc """
  End string encountered in object key context. Expect value.
  """
  def parse(<<?", ?:, t::binary>>, [:string, :key, :pair, :object | context], output) do
    debug "Found end of string key in object context.", t, context, output
    parse(t, [:value, :object | context], output <> <<?", ?,>>)
  end

  @doc """
  End a string context if a string terminator is reached.
  """
  def parse(<<?", t::binary>>, [:string | context], output) do
    debug "Found close quote in a string context, passing through", t, context, output
    parse(t, context, output <> <<?">>)
  end

  @doc """
  Pass through any characters that are not a string terminator in a string context.
  """
  def parse(<<char, t::binary>>, c = [:string | context], output) do
    debug "Passing through this character in a string context: #{<<char>>}", t, context, output
    parse(t, c, output <> <<char>>)
  end

  @doc """
  Digits during a number context.
  """
  def parse(<<n, t::binary>>, [:number | context], output) when n in @digits do
    debug "Found digit in number context: #{<<n>>}", t, context, output
    parse(t, [:number | context], output <> <<n>>)
  end

  @doc """
  Digits, when a value is expected. Sets number context.
  """
  def parse(<<n, t::binary>>, [:value | context], output) when n in @number_start do
    debug "Found digit while value expected: #{<<n>>}", t, context, output
    parse(t, [:number | context], output <> <<n>>)
  end

  @doc """
  Digits in a bare array. Sets number context.
  """
  def parse(<<n, t::binary>>, [:array | context], output) when n in @number_start do
    debug "Found digit while in array: #{<<n>>}", t, context, output
    parse(t, [:number, :array | context], output <> <<n>>)
  end

  @doc """
  Exponent followed by + during a number context. Drops the +.
  """
  def parse(<<?e, ?+, t::binary>>, [:number | context], output) do
    debug "Found exponent plus during a number context", t, context, output
    parse(<<?e>> <> t, [:number | context], output)
  end

  @doc """
  Exponent followed by - followed by a digit during a number context.
  Pushes an extra float onto the output for Elixir's sake.
  """
  def parse(<<?e, ?-, n, t::binary>>, [:number | context], output) when n in @digits do
    debug "Found exponent minus number during a number context", t, context, output
    parse(t, [:exponent | context], output <> <<?., ?0, ?e, ?-, n>>)
  end

  @doc """
  Exponent followed by a digit during a number context. Pushes an extra float onto the output for Elixir's sake.
  """
  def parse(<<?e, n, t::binary>>, [:number | context], output) when n in @digits do
    debug "Found exponent during a number context", t, context, output
    parse(t, [:exponent | context], output <> <<?., ?0, ?e, n>>)
  end

  # short circuit capital E exponent in a number context
  def parse(<<?E, t::binary>>, [:number | context], output) do
    parse(<<?e>> <> t, [:number | context], output)
  end

  @doc """
  Decimal during a number context. Pushes decimal context.
  """
  def parse(<<?., n, t::binary>>, [:number | context], output) when n in @digits do
    debug "Found decimal and digit #{<<n>>} during a number context", t, context, output
    parse(t, [:decimal | context], output <> <<?., n>>)
  end

  @doc """
  Digits during a decimal context.
  """
  def parse(<<n, t::binary>>, [:decimal | context], output) when n in @digits do
    debug "Found digit #{<<n>>} during a decimal context", t, context, output
    parse(t, [:decimal | context], output <> <<n>>)
  end

  @doc """
  Exponent followed by + during a decimal context. Drops the +.
  """
  def parse(<<?e, ?+, t::binary>>, [:decimal | context], output) do
    debug "Found exponent and + during a decimal context, dropping +", t, context, output
    parse(<<?e>> <> t, [:decimal | context], output)
  end

  @doc """
  Exponent followed by - followed by a digit during a decimal context.
  """
  def parse(<<?e, ?-, n, t::binary>>, [:decimal | context], output) when n in @digits do
    debug "Found exponent and - and digit #{<<n>>} during a decimal context, dropping decimal context and adding exponent context", t, context, output
    parse(t, [:exponent | context], output <> <<?e, ?-, n>>)
  end

  @doc """
  Exponent followed by a digit during a decimal context.
  """
  def parse(<<?e, n, t::binary>>, [:decimal | context], output) when n in @digits do
    debug "Found exponent and digit #{<<n>>} during a decimal context, dropping decimal context and adding exponent context", t, context, output
    parse(t, [:exponent | context], output <> <<?e, n>>)
  end

  # short circuit capital E exponent in a decimal context
  def parse(<<?E, t::binary>>, [:decimal | context], output) do
    parse(<<?e>> <> t, [:decimal | context], output)
  end

  @doc """
  Digits during an exponent context.
  """
  def parse(<<n, t::binary>>, [:exponent | context], output) when n in @digits do
    debug "Found digit during exponent context: #{<<n>>}", t, context, output
    parse(t, [:exponent | context], output <> <<n>>)
  end

  @doc """
  Drop exponent context if no more digits.
  """
  def parse(<<n, t::binary>>, [:exponent | context], output) when not n in @digits do
    debug "Dropping exponent context", t, context, output
    parse(<<n>> <> t, context, output)
  end

  @doc """
  Drop exponent context if no more input.
  """
  def parse("", [:exponent | context], output) do
    debug "Dropping exponent context- no more input"
    parse("", context, output)
  end

  @doc """
  Drop decimal context if no more digits.
  """
  def parse(<<n, t::binary>>, [:decimal | context], output) when not n in @digits do
    debug "Dropping decimal context", t, context, output
    parse(<<n>> <> t, context, output)
  end

  @doc """
  Drop decimal context if no more input.
  """
  def parse("", [:decimal | context], output) do
    debug "Dropping decimal context- no more input"
    parse("", context, output)
  end

  @doc """
  Drop number context if no more digits.
  """
  def parse(<<n, t::binary>>, [:number | context], output) when not n in @digits do
    debug "Dropping number context", t, context, output
    parse(<<n>> <> t, context, output)
  end

  @doc """
  Drop number context if no more input.
  """
  def parse("", [:number | context], output) do
    debug "Dropping number context- no more input"
    parse("", context, output)
  end

  @doc """
  Objects! This should be fun.
  First when value expected. Push object context.
  """
  def parse(<<?{, t::binary>>, [:value | context], output) do
    debug "Found object start when value expected. Pushing object context.", t, context, output
    parse(t, [:object | context], output <> <<?[, ?{>>)
  end

  @doc """
  Object encountered inside an array context. Push object context.
  """
  def parse(<<?{, t::binary>>, context = [:array | _], output) do
    debug "Found object start when inside array. Pushing object context.", t, context, output
    parse(t, [:object | context], output <> <<?[, ?{>>)
  end

  @doc """
  String encountered inside object. Push string, key and pair context.
  NOTE: This will create atoms from string keys. Perhaps that's a DDoS attack vector (see: Ruby symbols)?
        Maybe add a switch/mode later.
  """
  def parse(<<?", t::binary>>, [:object | context], output) do
    debug "Found string inside bare object context. Setting string key and pair context.", t, context, output
    parse(t, [:string, :key, :pair, :object | context], output <> <<?:, ?">>)
  end

  @doc """
  Object close character. Pop any existing pair context.
  """
  def parse(<<?}, t::binary>>, [:pair, :object | context], output) do
    debug "Closing pair context", t, context, output
    parse(<<?}>> <> t, [:object | context], output)
  end

  @doc """
  Object close character. Pop object context.
  """
  def parse(<<?}, t::binary>>, [:object | context], output) do
    debug "Closing object context", t, context, output
    parse(t, context, output <> <<?},?]>>)
  end


  # fallthrough... problem?
  def parse(json_string, context, output) do
    err = "WARNING: JSON string not parseable"
    debug err, json_string, context, output
    {:error, err}
  end

  defp debug(_, _ \\ "", _ \\ [], _ \\ "") do
    :ok
  end

  # defp debug(msg, json \\ "", context \\ [], output \\ "") do
  #   IO.puts msg
  #   IO.puts " json:    " <> inspect json
  #   IO.puts " context: " <> inspect context
  #   IO.puts " output:  " <> inspect output
  # end
end

# run this inline suite with "elixir #{__ENV__.file} test"
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

    # success assertions
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

    # error assertions
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
