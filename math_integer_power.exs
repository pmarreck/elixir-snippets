
# Integer power function, for anyone curious, with test coverage

# Inspired by:
# 1) needing it, because :math.pow had rounding errors with big numbers (yay floating point!), and
# 2) http://stackoverflow.com/questions/101439/the-most-efficient-way-to-implement-an-integer-based-power-function-powint-int
# I took that and basically applied "functional transformations" to it, to get the below code.
# According to Stackoverflow and Google, this algorithm is one of (but probably not THE) most efficient way to do this.
# Depends on Bitwise from the Elixir standard library.
# Note: I didn't define this for negative exponents. Yet.

defmodule Math do
  use Bitwise, only_operators: true

  # integer power function
  def ipow(base, exp) when is_integer(base) and is_integer(exp) and exp > -1 do
    _ipow(1, base, exp)
  end

  # optimization for base 2
  defp _ipow(1, 2, exp) do
    1 <<< exp
  end
  # final case
  defp _ipow(result, _, 0) do
    result
  end
  defp _ipow(result, base, exp) when rem(exp, 2) == 1 do
    _ipow(result * base, base * base, exp >>> 1)
  end
  defp _ipow(result, base, exp) do
    _ipow(result, base * base, exp >>> 1)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule MathIpowTest do
    use ExUnit.Case, async: true

    test "integer power zeroes" do
      # this is apparently controversial:
      # http://www.askamathematician.com/2010/12/q-what-does-00-zero-raised-to-the-zeroth-power-equal-why-do-mathematicians-and-high-school-teachers-disagree/
      assert Math.ipow(0,0) == 1
    end
    test "integer power base 2 optimization" do
      assert Math.ipow(2,5) == 32
    end
    test "integer power base 10" do
      assert Math.ipow(10, 5) == 100000
    end
    test "integer power gigantic mofo" do
      assert Math.ipow(123, 456) == 99250068772098856700831462057469632637295940819886900519816298881382867104749399077921128661426144638055424236936271872492800352741649902118143819672601569998100120790496759517636465445895625741609866209900500198407153244604778968016963028050310261417615914468729918240685487878617645976939063464357986165711730976399478507649228686341466967167910126653342134942744851463899927487092486610977146112763567101672645953132196481439339873017088140414661271198500333255713096142335151414630651683065518784081203678487703002802082091236603519026256880624499681781387227574035484831271515683123742149095569260463609655977700938844580611931246495166208695540313698140011638027322566252689780838136351828795314272162111222231170901715612355701347552371530013693855379834865667060014643302459100429783653966913783002290784283455628283355470529932956051484477129333881159930212758687602795088579230431661696010232187390436601614145603241902386663442520160735566561
    end
    test "integer power negative base" do
      assert Math.ipow(-2, 2) == 4
      assert Math.ipow(-2, 5) == -32
    end

  end
end
