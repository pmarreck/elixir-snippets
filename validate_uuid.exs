defmodule UUIDValidate do
  @allowed_chars ~w[0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f]
  @uuid_format "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  defguard is_uuid(uuid, format \\ @uuid_format)
  defguard is_uuid(c <> uuid, (f <> format)) when ((f == "x" and (c in @allowed_chars)) or c == f) and is_uuid(uuid, format)
  def validate(uuid) when is_uuid(uuid) do
    true
  end
  def validate(uuid) do
    false
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule UUIDValidationTest do
    use ExUnit.Case, async: true
    test "passes validation" do
      assert UUIDValidate.validate("123e4567-e89b-12d3-a456-426652340000")
    end
    test "fails validation" do
      refute UUIDValidate.validate("123e4567e89b12d3a456-426652340000")
      refute UUIDValidate.validate(<<?1,?2,?3,?e,?4,?5,?6,?7,?-,?e,?8,?9,?b,?-,?1,?2,?d,?3,?-,?a,?4,?5,?6,?-,?4,?2,?6,?6,?5,?2,?3,?4,?0,?0,?0,?0>>)
      refute UUIDValidate.validate("")
    end
  end
end
