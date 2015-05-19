# MRI hack to enable tail-call optimization making the recursive version not blow the stack:
# I'm using ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-darwin13.0]

RubyVM::InstructionSequence.compile_option = {
  tailcall_optimization: true,
  trace_instruction: false
}

class Fib
  def run_enumerative(n)
    # with hash memoization... real slow tho
    # n.times.reduce([0,1]){|memo, num| memo + [memo[-2] + memo[-1]]}
    # with a lambda
    (0..n).inject([1,0]) { |(a,b), _| [b, a+b] }[0]
  end

  def run_procedural(n)
    curr, nxt = 0, 1
    n.times {
      curr, nxt = nxt, curr + nxt
    }
    curr
  end

  def run_recursive(n)
    _run_recursive(n, 0, 1)
  end

  # this hack does work, but as you can see, looks so hacky
  # If you do not use this, the stack will blow for any arg of any significant size.
  # Doesn't mean it will run fast, though...
  # Taken from http://nithinbekal.com/posts/ruby-tco/
  RubyVM::InstructionSequence.new(<<-EOS).eval
    def _run_recursive(n, res, nxt)
      return res unless n > 0
      _run_recursive(n-1, nxt, res+nxt)
    end
  EOS

end

times = 1000000


# I commented the recursive version out because, even though it doesn't blow the stack,
# it took waaaay too long for an input of 500000

# begin
#   t = Time.now
#   Fib.new.run_recursive times
#   recursive_total_time = Time.now - t
# rescue SystemStackError => e
#   puts "Ruby recursive solution blows up with fib(#{times})."
#   puts e.inspect
# end

t = Time.now
Fib.new.run_procedural times
procedural_total_time = Time.now - t

t = Time.now
Fib.new.run_enumerative times
enumerative_total_time = Time.now - t

# puts "Running Ruby recursive fib(#{times}) takes #{recursive_total_time} seconds"
puts "Running Ruby procedural fib(#{times}) takes #{procedural_total_time} seconds"
puts "Running Ruby enumerative fib(#{times}) takes #{enumerative_total_time} seconds"
