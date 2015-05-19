module FizzBuzz

  def self.fizzbuzz(num = 100)
    # Mapping this way is way slower in Ruby than Elixir
    # (1..10000000).map do |n|
    #     # Use string interpolation to construct the expected responses
    #     output = "#{n % 3 == 0 ? "Fizz" : ""}#{n % 5 == 0 ? "Buzz" : ""}"
    #     # Print the number if it's not a special case
    #     output.empty? ? n : output
    # end

    # Even this method, which mutates an array, takes 40% longer than Elixir
    result = []
    1.upto(num).each do |n|
      result << case n % 15
      when 3, 6, 9, 12
        :fizz
      when 5, 10
        :buzz
      when 0
        :fizzbuzz
      else
        n
      end
    end
    result
  end

  def self.test
    raise "something is wrong in FizzBuzz" unless FizzBuzz.fizzbuzz(15) == [1, 2, :fizz, 4, :buzz, :fizz, 7, 8, :fizz, :buzz, 11, :fizz, 13, 14, :fizzbuzz]
  end
end

FizzBuzz.test
FizzBuzz.fizzbuzz(10000000)
