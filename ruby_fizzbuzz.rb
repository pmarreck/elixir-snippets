
# Mapping this way is way slower in Ruby than Elixir
# (1..10000000).map do |n|
#     # Use string interpolation to construct the expected responses
#     output = "#{n % 3 == 0 ? "Fizz" : ""}#{n % 5 == 0 ? "Buzz" : ""}"
#     # Print the number if it's not a special case
#     output.empty? ? n : output
# end

# Even this method, which mutates an array, takes 40% longer than Elixir
result = []
1.upto(10000000).each do |n|
    # Use string interpolation to construct the expected responses
    output = "#{n % 3 == 0 ? "Fizz" : ""}#{n % 5 == 0 ? "Buzz" : ""}"
    # Print the number if it's not a special case
    result << output.empty? ? n : output
end
