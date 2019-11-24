defmodule Xml do

  def parse(xml) when is_binary(xml) do
    do_parse("", xml, [])
  end

  defp simplify([e, ""]), do: e

  defp simplify([_head | _rest] = fine) do
    fine
  end

  defp do_parse(_acc, "", []) do
    ""
  end

  defp do_parse("", <<?<, ?/, rest::binary>>, [current_tag | stack]) do
    true = String.starts_with?(rest, current_tag <> ">")
    rest = String.trim_leading(rest, current_tag <> ">")
    {rest, stack}
  end

  defp do_parse(inprog_val, <<?<, ?/, rest::binary>>, [current_tag | stack]) do
    true = String.starts_with?(rest, current_tag <> ">")
    rest = String.trim_leading(rest, current_tag <> ">")
    [inprog_val | {rest, stack}]
  end

  defp do_parse("", <<?<, rest::binary>>, stack) do
    case do_parse("", rest, stack) do
      {rest, stack} -> []
  end

  defp do_parse(inprog_val, <<?<, rest::binary>>, stack) do
    [inprog_val | do_parse("", rest, stack)] |> simplify()
  end

  defp do_parse(accum, <<?\s, _rest::binary>> = attr_and_or_rest, stack) do
    {attribs, rest} = do_gather_possible_attribs(%{}, attr_and_or_rest)
    %{"#{accum}" => %{attribs: attribs, vals: do_parse("", rest, [accum | stack])}}
  end

  defp do_parse(accum, <<?>, rest::binary>>, stack) do
    {this_child_struct, remainder} = do_parse("", rest, [accum | stack])
    [%{"#{accum}" => this_child_struct} | do_parse("", remainder, stack)]
  end

  # parse values
  defp do_parse(accum, <<next_letter::utf8, rest::binary>>, stack) do
    do_parse(accum <> <<next_letter>>, rest, stack)
  end

  # just slurp up the name=value pair(s) using regex and return as a map
  @name_value_pairs_regex ~r/\s+(\w+)="?([^>"]*)"?/u
  @capture_to_end_of_tag ~r/[^>]+/
  defp do_gather_possible_attribs(attribs, rest) do
    these_attribs = Regex.run(@capture_to_end_of_tag, rest, capture: :first) |> List.first
    pairs = Regex.scan(@name_value_pairs_regex, these_attribs, capture: :all_but_first)
    attribs = Map.merge(attribs, pairs |> Map.new(fn [key, value] -> {key, value} end))
    rest = Regex.replace(~r/[^>]*>/u, rest, "", global: false)
    {attribs, rest}
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule XmlTest do
    use ExUnit.Case, async: true

    test "parses just a root node with a value" do
      assert Xml.parse("<root>value</root>") == %{"root" => "value"}
    end

    test "parses a root node with no value" do
      assert Xml.parse("<a></a>") == %{"a" => ""}
    end

    test "parses two nested tags with a value" do
      assert Xml.parse("<a><b>c</b></a>") == %{"a" => %{"b" => "c"}}
    end

    test "parses multiple identical tags" do
      assert Xml.parse("<a><b>foo</b><b>bar</b></a>") ==
        %{"a" =>
          [
            %{"b" => "bar"},
            %{"b" => "foo"}
          ]
        }
    end

    test "parses an attribute" do
      assert Xml.parse("<a href=\"http\">b</a>") == %{"a" => %{:attribs => %{"href" => "http"}, :vals => "b"}}
    end

    test "parses multiple identical tags with attributes" do
      assert Xml.parse("<a href=\"http\"><b id=\"1\">foo</b><b>bar</b>text</a>") ==
        %{"a" =>
          %{attribs: %{"href" => "http"}, vals: [
            %{"b" =>
              %{attribs: %{"id" => "1"}, vals: [
                "bar"
              ]}
            },
            %{"b" =>
              %{attribs: %{}, vals: ["foo"]}
            }
          ]}
        }
    end

    test "raises if end tag doesn't match start tag" do
      assert_raise MatchError, fn -> Xml.parse("<root>value</rot>") end
    end

  end
end
