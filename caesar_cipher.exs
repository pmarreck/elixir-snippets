# The one to beat:
[n,p]=IO.gets("")|>String.split",";IO.puts for<<c<-p>>,do: c<97&&c||97+rem c-71-String.to_integer(n),26

# my submission with Greg's tweak:
{n,","<>p}=Integer.parse IO.gets"";IO.puts for<<c<-p>>,do: c<?a&&c||?a+rem c-71-n,26

### EXPLANATION/BREAKDOWN
Integer.parse IO.gets""
# This gets input from the terminal (IO.gets), you have to supply a prompt argument ("") but due to an idiosyncrasy
# with how Elixir parses arguments you can avoid using the parens in this case.
# The result of that is then passed as an argument to Integer.parse,
# which tries to find an integer-looking number at the beginning of the string,
# and returns that PLUS the rest of the string (binary) that IS NOT integer-looking, as a tuple:
> Integer.parse("-15,peter")
{-15, ",peter"}
# This was the key insight/shortcut that got me to shave ~15 characters off the solution. Moving on...
{n, "," <> p} = ...
# Basically, take the tuple output by Integer.parse and pattern-match on that, putting
# the integer part into "n" and skipping the comma (but ALSO pattern-matching on it- this will error if there is no comma there!)
# and pattern-matching the rest of the string into "p".
# <> is normally a way to concatenate two strings:
> "a" <> "bee"
"abee"
# but when pattern-matching on a binary it also allows you to describe the structure of the binary you're looking for:
> "letters" <> special_characters = "lettersand these are special"
"lettersand these are special"
> special_characters
"and these are special"
# Note that when using it in pattern-matching, the "fixed" part (the literal) has to come first, you can't do this for example:
> special_characters <> "special" = "lettersand these are special"
** (ArgumentError) the left argument of <> operator inside a match should be always a literal binary as its size cant be verified, got: special_characters
# This really starts to showcase the deep pattern-matching-while-assigning capability of Erlang/OTP/Elixir.
# I put the spaces back in here for legibility but they're optional so I removed them.
;
# Semicolon just means "now start another statement"
for <<c<-p>>, do:
# ok... this is some cleverness here. the "for" construct in Elixir is quite powerful and is best just read-up on:
# https://hexdocs.pm/elixir/Kernel.SpecialForms.html#for/1
# The <<c<-p>> bit is a "binary comprehension" form. so basically what this means is:
# Take the full value of p (a string or binary), but "for" each item, take a single 8 bit character from it BUT AS AN INTEGER (the ascii value)
# and then stick that into "c". You can read this aloud as "for ascii 8-bit integer c from binary p"
# This might make more sense if you try this in console:
?a
# The result of this should be 97, the ascii value of the letter "a". ?a is a shorthand in Elixir
# for "give me the ascii value, as integer, of the following ascii character".
# Now try this:
<<97>>
# The result should be "a". <<>> is a binary literal, whatever numbers you stick in there get interpreted as ASCII bytes.
# So this is why <<c<-p>> means "take a byte from p and treat as integer value".
# If it was just "for c<-p" then it would take the binary/string letter and not the integer value.
# So if the first letter was "a" then c would get assigned "a" in the latter example, and not 97.
# I think the default comprehension for binaries/strings is taking 8 bits i.e. 1 byte at a time or possibly 1 unicode letter at a time,
# I'd have to look it up. (Note that 1 unicode letter can be more than 1 byte)
# Moving on, the "do:" just says "given the previous comprehension, do the following for each value, iteratively"
c<?a&&c||?a+rem c-71-n,26
# alright, let's break this up further as this is pretty dense.
# Even I don't fully understand how this works, someone else figured out this part lol
rem c-71-n, 26
# "the remainder of c minus 71 minus n, when divided by 26"
# So basically, c is a character value in ascii. If you subtract 71 from it
# (which is 97 - 26 i.e. "the ascii value of a, minus the total number of lowercase letters in the alphabet",
# and then subtract n (the number that you told it to rotate the character set by),
# and then figure out the remainder when dividing by 26, this gives you the number of the letter in the alphabet to convert this character to.
# So then you just add the lowest lettered ascii value to that (?a, remember?) and you get the new ascii value, which is:
# (optional spaces and parens added for clarity)
?a + rem(c-71-n, 26)
# Moving on to the previous bit:
c<?a&&c||
# ok. "if c is less than ascii-a AND c OR..."
# So there's a thing in boolean logic, I forgot the name of the principle (boolean shortcut logic?) but basically what it says is this:
# All values when interpreted as Booleans are either nil or false (both interpreted as "false"), OR true.
# if you 'a AND b', and both are true, return the value of b, or return false:
> true && 5
5
# if you 'a OR b', and either is true, then return the value of the first "truthy" value, or false:
> "this" || "that"
"this"
> "this" || nil
"this"
> nil || "that"
"that"
# Since anything not nil or false is true when it comes to booleans, all of this works out.
# So now the full portion:
c<?a&&c||?a+rem c-71-n,26
# "if c is less than ascii-a, return c (via boolean AND shortcut), OR return ascii-a plus the remainder of (c-71-n) when dividing by 26"
# So basically, just pass through any character that is not a-z, otherwise do this computation on the ascii of that character and return the new character.
IO.puts
# This just prints out the character ascii value AS A BINARY (because of the for<<>> construct, the binary comprehension. So even though each character is TAKEN one at a time as its ascii value, it is "comprehended" when output as a binary value.)
# BOOM!
{n,","<>p}=Integer.parse IO.gets"";IO.puts for<<c<-p>>,do: c<?a&&c||?a+rem c-71-n,26
# Get it now? lol.