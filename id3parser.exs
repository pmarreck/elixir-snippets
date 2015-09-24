# A refactor of Benjamin Tan's ID3v1 parsing code at http://benjamintan.io/blog/2014/06/10/elixir-bit-syntax-and-id3/

defmodule ID3Parser do

  @id3_tag_size 128

  def parse(file_name, io_input \\ &File.read/1, io_output \\ &IO.puts/1) do
    case io_input.(file_name) do
      {:ok, binary} ->
        {title, artist, album, year, comment} = parse_binary(binary)

        io_output.(title)
        io_output.(artist)
        io_output.(album)
        io_output.(year)
        io_output.(comment)

      _ ->
        io_output.("Couldn't open #{file_name}")
    end
  end

  def parse_binary(binary) when byte_size(binary) > @id3_tag_size do
    mp3_byte_size = (byte_size(binary) - @id3_tag_size)
    << _ :: binary-size(mp3_byte_size), id3_tag :: binary >> = binary

    << "TAG",
        title   :: binary-size(30),
        artist  :: binary-size(30),
        album   :: binary-size(30),
        year    :: binary-size(4),
        comment :: binary-size(30),
        _rest   :: binary >> = id3_tag

    {title, artist, album, year, comment}
  end

end

# Now you can easily test both the "parse" and "parse_binary" functions in isolation,
# and the latter is additionally functionally pure.
