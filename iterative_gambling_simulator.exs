defmodule IterativeGamblingSimulator do
  def start(), do: start(0.49, 2000, 100, 1)

  def start(win_odds, games_left, 0, bet_per_game) do
    IO.puts "Ran out of money with #{games_left} games left to play."
    IO.puts "Win odds: #{win_odds * 100}%"
    IO.puts "Bet per game: $#{bet_per_game}"
  end

  def start(win_odds, 0, cash_left, bet_per_game) do
    IO.puts "We didn't go bankrupt!"
    IO.puts "Win odds: #{win_odds * 100}%"
    IO.puts "Bet per game: $#{bet_per_game}"
    IO.puts "Cash left: $#{cash_left}"
  end

  def start(win_odds, num_games, start_cash, bet_per_game) when num_games > 0 do
    win = :rand.uniform < win_odds
    cash_left = start_cash - bet_per_game
    new_cash = if win do
      cash_left + (bet_per_game * 2)
    else
      cash_left
    end
    start(win_odds, num_games - 1, new_cash, bet_per_game)
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule IterativeGamblingSimulatorTest do
    use ExUnit.Case, async: true
    import IterativeGamblingSimulator
    test "49% double or nothing, 2000 games, $100 cash, $1 per game" do
      start()
    end
  end
end
