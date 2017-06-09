# ruby_factorial_with_iterator.rb
def factorial_with_iterator(n)
  res = 1
  (1..n).each{|time| res *= time}
  res
end

factorial_with_iterator(200000)
