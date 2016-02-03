## Converting a Random Maze Generator that uses External Mutable State to a Deterministic (Testable) Maze Generator that is More Functional ##

Before you refactor ANY code, you have to cover it with a test. Which presented me here with a conundrum, a maze being a randomly-generated thing. The trick, of course, is to make it "deterministically random" so that each run of the test produces the same "random" maze, which can then be asserted against.

The first changes to the code involved making the random seed injectable, and separating the printing-out of the maze from the side-effect-free "model" of the maze, so I added a "generate" function to just do the maze computation.

The first stab at making it deterministically random was to pass in the random seed for `:random.seed(rand_seed)` to the "generate" function, but that didn't seem to work.

After more investigation, I noticed that the following command produces different output every time, which made no sense:
`:random.seed({1,2,3}); Enum.shuffle([1,2,3,4])`

After discussion with the helpful folks on the #elixir-lang IRC channel, it turns out that `Enum.shuffle` uses the newer source of randomness API `:rand`, NOT `:random`, so reseeding THAT code as well with
`:rand.seed(:exs64, {1,2,3}); Enum.shuffle([1,2,3,4])`
made it the same every time! So for now I seeded both.

NOTE: It is possible to change the assertion to match the output using the default seed for `:random.seed`, remove that particular reseeding, and the test would still pass (turns out that in Erlang, "random" is actually deterministic per-process unless manually reseeded), but I liked it being explicit.

Once I made it deterministic and added a passing test, it was time to refactor out the Process dictionary calls and make the code more "functional." The process dict calls... *work*, but they bother me because they're very "object-oriented", reminding me of updating state in some singleton object in Ruby-land. And even though this is a *process* dictionary and guaranteed to be confined to this process, I just didn't like the style- you're basically sticking values "into the aether" in one function and then pulling them "out of the aether" in another function, that's not functional at all, and we're on this bandwagon so why not follow it through, you know?

Anyway, this step was trickier and involved maintaining some state such as width, height, and the maze data itself in a Map, and passing that around (as well as having it be the default return value for most functions). I was able to take advantage of the Elixir 1.2 implementation of Map which relies on the new, significantly-faster Erlang 18 "maps" implementation underneath which takes advantage of HAMT (hash array mapped trie), meaning Elixir finally has a native key-value store that scales well.

I cannot emphasize enough that having merely a SINGLE TEST CASE around to cover the 5x5 case was an invaluable aid to doing this refactor. For example, at first it was failing because it was just outputting a plain grid- turns out that the "walk" function was losing track of the updated maze state in a couple of places.

If you run the "performance" check on the page, on my laptop the old method (state mutation via process dictionary) took about 10 seconds and the new method (using immutable state updates) took about 11 seconds. So the old way is 10% faster, IMHO an acceptable price to pay for more functional code. I imagine it was significantly faster than the old implementation of Map.

It's possible that this code can be further optimized, probably by changing how the algorithm builds the maze (I mostly did a direct translation from the old code, for the sake of comparison).

The difference is subtle, but IMHO, important and worth learning how to do.
