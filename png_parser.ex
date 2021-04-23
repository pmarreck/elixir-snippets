defmodule Expng do

  defstruct [:width, :height, :bit_depth, :color_type, :compression, :filter, :interlace, :chunks]

  def png_parse(<<
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
                  _length :: size(32),
                  "IHDR",
                  width :: size(32),
                  height :: size(32),
                  bit_depth,
                  color_type,
                  compression_method,
                  filter_method,
                  interlace_method,
                  _crc :: size(32),
                  chunks :: binary>>) do
    png = %Expng{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_type: color_type,
      compression: compression_method,
      filter: filter_method,
      interlace: interlace_method,
      chunks: []}

    png_parse_chunks(chunks, png)
  end

  # defp i(thing) do
  #   IO.inspect(thing, limit: 100_000, printable_limit: 100_000, pretty: true)
  # end

  defp deflate(data) do
    z = :zlib.open()
    :zlib.inflateInit(z)
    [uncompressed] = :zlib.inflate(z, data)
    :zlib.close(z)
    uncompressed
  end

  defp parse_plte(binary, list \\ [])
  defp parse_plte(<<>>, list) do
    Enum.reverse(list)
  end
  defp parse_plte(<<value :: binary-size(3), rest :: binary>>, list) do
    <<r, g, b>> = value
    parse_plte(rest, [{r, g, b} | list])
  end

  defp png_parse_chunks(<<
                        length :: size(32),
                        chunk_type :: binary - size(4),
                        chunk_data :: binary - size(length),
                        crc :: size(32),
                        chunks :: binary>>, png) do
    chunk_data = case chunk_type do
      "IDAT" -> deflate(chunk_data)
      "tEXt" -> List.to_tuple(String.split(chunk_data, <<0>>))
      "PLTE" -> parse_plte(chunk_data)
      _ -> chunk_data
    end
    chunk = %{length: length, chunk_type: chunk_type, data: chunk_data, crc: crc}
    png = %{png | chunks: [chunk | png.chunks]}

    png_parse_chunks(chunks, png)
  end

  defp png_parse_chunks(<<>>, png) do
    %{png | chunks: Enum.reverse(png.chunks)}
  end
end
