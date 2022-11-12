### Design Goals ###
# The point of this code is to come up with a good visual representation/encoding of binary data that can be represented simply in a UTF-8 string;
# that is, the design priorities are:
# 1) visually distinct
# 2) conformant to printable ASCII 0-127 (so embedded text is instantly recognizable)
# 3) each representation is only the width of 1 character (although internally may be multibyte) so that printouts are as long as the
#    underlying byte length, but no longer; this made solutions like \n and whatnot infeasible
# 4) for control characters and nonprintable characters and values from 128-255, use a representation that is ideally only 2 bytes, but if no workable
#    substitute exists in the 2 byte Unicode character set, 3 bytes is "OK"
# 5) Easily copyable, pastable, and printable (possibly even OCR'able)
# 6) Less memory-consuming and more immediately useful (especially visually) than hexadecimal encoding
# 7) Ideally useful in debugging/testing environments but can also be used as a general binary representation in code (to be decoded right before use of course)
# 8) avoid use of emoji due to 4-byte requirement and "visually jarring"; so for example, this is not useful https://ayende.com/blog/177729/emoji-encoding-a-new-style-for-binary-encoding-for-the-web

defmodule PrintableBinary do

  def encode(0), do: "∅" # \0 or possibly ␀ but the spacing on that gets weird; see https://en.wikipedia.org/wiki/C0_and_C1_control_codes
  def encode(1), do: "¯" # Start of Heading
  def encode(2), do: "«" # Start of Text
  def encode(3), do: "»" # End of Text
  def encode(4), do: "ϟ" # control-D, or "end of transmission" signal. 3bytes: ⌁, 2bytes: ϟ
  def encode(5), do: "¿" # Enquiry (ENQ)
  def encode(6), do: "¡" # Acknowledge (ACK)
  def encode(7), do: "ª" # \a (bell). 2bytes: ª. 4 bytes: 🔔
  def encode(8), do: "⌫"  # \b (backspace). 3bytes: ⌫
  def encode(9), do: "⇥" # \t (tab). 3 bytes: ⇥
  def encode(10), do: "⇩" # \n (newline or line feed). 3bytes: ⇩
  def encode(11), do: "↧" # \v (vertical tab). 3bytes: ↧
  def encode(12), do: "§" # \f 2bytes: § (could also use ↡ for form feed/page break, but that takes 3 bytes and is less visually distinct)
  def encode(13), do: "⏎" # \r (carriage return). 3bytes: ⏎
  def encode(14), do: "ȯ" # Shift Out
  def encode(15), do: "ʘ" # Shift Back In
  def encode(16), do: "Ɣ" # Data Link Escape
  def encode(17), do: "¹" # (XON) Device Control 1
  def encode(18), do: "²" # Device Control 2
  def encode(19), do: "º" # (XOFF) Device Control 3
  def encode(20), do: "³" # Device Control 4 (used 3 since I wanted 0 for XOFF and using ⁴ is 3 bytes)
  def encode(21), do: "Ͷ" # Negative Acknowledge (NAK)
  def encode(22), do: "ɨ" # Synchronous Idle
  def encode(23), do: "¬" # End of Transmission Block
  def encode(24), do: "©" # Cancel (cancel previous input)
  def encode(25), do: "¦" # End of Medium
  def encode(26), do: "Ƶ️" # control-Z, SIGTSTP/stop/suspend, "soft EOF", possibly consider 🛑 or ⏸? all 4 bytes tho
  def encode(27), do: "⎋" # \e (escape). 3 bytes: ⎋.
  def encode(28), do: "Ξ" # File Separator
  def encode(29), do: "ǁ" # Group Separator
  def encode(30), do: "ǀ" # Record Separator
  def encode(31), do: "¶" # Unit Separator

  # fallthrough to the 3 byte control character symbolic representations (hard to read/indistinct) when no clear 2-byte substitute provided
  # Note: This fallthrough isn't currently reachable because all the values are now accounted for above
  # but you can comment those out if you want this type of representation instead
  def encode(n) when is_integer(n) and n > -1 and n < 32 do
    <<(n + 9216)::utf8>>
  end

  # space. make it visible with a ␣. also prevents unwanted line breaks on actual spaces.
  def encode(32), do: "␣" # \s ?

  # encode double quote to utf8 757 so that it doesn't need to get escaped
  # I wanted something that looked enough like a double quote to be recognizable
  # but different enough to not be mistaken for the normal " character.
  def encode(34), do: "˵"

  # encode backslash to Ʌ so that it doesn't need to get escaped
  def encode(92), do: "Ʌ"

  def encode(n) when is_integer(n) and n > 32 and n < 127 do
    to_string([n])
  end

  # forward delete
  def encode(127), do: "⌦"

  # move encodings of Ø and ø (both 2 bytes) so that ∅ (3 bytes) is visually distinct for NULL
  def encode(152), do: "Ō"
  def encode(184), do: "ŏ"

  def encode(n) when is_integer(n) and n > 127 and n < 192 do
    <<195, n>>
  end

  def encode(n) when is_integer(n) and n > 191 and n < 256 do
    <<196, (n - 192) + 0x80>>
  end

  def encode(n) when is_integer(n) and n > 255 do
    raise "Invalid byte to encode: #{n}"
  end

  def encode(n) when is_list(n) do
    encode(codepoint_list_to_binary(n))
  end

  def encode(<<>>), do: ""
  def encode(<<c::8, rest::binary>>) do
    encode(c) <> encode(rest)
  end

  def to_bytelist(<<>>), do: []
  def to_bytelist(<<c::8, rest::binary>>) do
    [c | to_bytelist(rest)]
  end

  def codepoint_list_to_binary(list) when is_list(list) do
    do_codepoint_list_to_binary("", list)
  end
  defp do_codepoint_list_to_binary(bin, []), do: bin
  defp do_codepoint_list_to_binary(bin, [cp | lst]) when cp > -1 and cp < 256 do
    do_codepoint_list_to_binary(bin <> <<cp>>, lst)
  end


  @decode_charset "∅¯«»ϟ¿¡ª⌫⇥⇩↧§⏎ȯʘƔ¹²º³Ͷɨ¬©¦Ƶ⎋Ξǁǀ¶␣!˵#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[Ʌ]^_`abcdefghijklmnopqrstuvwxyz{|}~⌦ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ŌÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷ŏùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿ"
                  |> String.codepoints

  def decode(<<>>), do: ""
  # some UTF8 weirdness to hack around... possibly replace offending character, but this works for now
  def decode(<<n::utf8, bin::binary>>) when n == 65039, do: decode(bin)
  def decode(<<n::utf8, bin::binary>>) do
    code = Enum.find_index(@decode_charset, fn cs -> <<n::utf8>> == cs end)
    unless code do
      raise "Character #{inspect(<<n::utf8>>)} with codepoint #{n} and length #{byte_size(<<n::utf8>>)} was not in the decode list"
    end
    <<code>> <> decode(bin)
  end
  def decode(n) when is_list(n) do
    Enum.map(n, fn c -> decode(c) end)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule PrintableBinaryTest do
    use ExUnit.Case, async: true
    alias PrintableBinary, as: PB

    # some helper funcs
    defp random_stream(min..max) when max >= min do
      max = max + 1
      seed = :rand.seed_s(:exsplus)
      Stream.unfold(seed, fn acc ->
        {next, acc} = :rand.uniform_s(acc)
        {trunc(min + (next * (max - min))), acc}
      end)
    end

    defp random_binary_data(len) do
      random_stream(0..255) |> Enum.take(len) |> PB.codepoint_list_to_binary
    end

    test "encoding control chars 0-32" do
      assert "∅¯«»ϟ¿¡ª⌫⇥⇩↧§⏎ȯʘƔ¹²º³Ͷɨ¬©¦Ƶ️⎋Ξǁǀ¶␣" == (0..32) |> Enum.to_list |> PB.codepoint_list_to_binary |> PB.encode
    end

    test "encoding printable chars 33-127" do
      assert "!˵#$%&'()*+,-./0123456789:;<=>?@" == (33..64) |> Enum.to_list |> to_string |> PB.encode
      assert "ABCDEFGHIJKLMNOPQRSTUVWXYZ[Ʌ]^_`abcdefghijklmnopqrstuvwxyz{|}~⌦" == (65..127) |> Enum.to_list |> PB.codepoint_list_to_binary |> PB.encode
    end

    test "encoding 128-191" do
      assert "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ŌÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷ŏùúûüýþÿ" = (128..191) |> Enum.to_list |> PB.codepoint_list_to_binary |> PB.encode
    end

    test "encoding 192-255" do
      assert "ĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿ" = (192..255) |> Enum.to_list |> PB.codepoint_list_to_binary |> PB.encode
    end

    test "making visible some text within some binary data" do
      prefix = random_binary_data(10)
      suffix = random_binary_data(10)
      test_binary = prefix <> "there once was a man in München\r\n" <> suffix
      # There's still an issue with cursor placement/spacing using this encoding, at least in my editor...
      # Tabling for now
      assert PB.encode(prefix) <> "there␣once␣was␣a␣man␣in␣Măünchen⏎⇩" <> PB.encode(suffix) == PB.encode(test_binary)
    end

    test "all encodings are unique" do
      all_symbols = (0..255) |> Enum.to_list |> PB.codepoint_list_to_binary |> PB.encode |> String.split("", trim: true)
      assert 256 == all_symbols |> Enum.uniq |> length
    end

    test "encoding and then decoding random binary result gives same argument" do
      charlist = random_stream(0..255) |> Enum.take(2000)
      charlist_as_binary = PB.codepoint_list_to_binary(charlist)
      assert charlist_as_binary == charlist |> PB.encode |> PB.decode
      assert charlist_as_binary == charlist_as_binary |> PB.encode |> PB.decode
      # IO.inspect byte_size(bin |> PB.encode) # ~67% expansion in size for random binary data, reasonable?
    end

    test "encoding problematic binaries doesn't raise" do
      PrintableBinary.encode(<<198, 181, 239, 184, 143>>)
    end

  end
else
  mode = System.argv |> List.first # either "encode" or "decode"
  input = IO.read(:stdio, :all)
  case mode do
    "encode" -> input |> PrintableBinary.encode |> IO.puts
    "decode" -> input |> PrintableBinary.decode |> IO.puts
    blank when blank in ["",nil] -> IO.puts "Usage: #{Path.basename(__ENV__.file)} [ test | encode|decode < input.bin ]\nAnother example: head -c 500 /dev/urandom | elixir printable_binary.exs encode"
    _ -> raise "Unknown mode argument '#{mode}', please use either 'encode' or 'decode', or run the test suite with 'test'"
  end
end
