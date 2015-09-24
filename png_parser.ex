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

  defp png_parse_chunks(<<
                        length :: size(32),
                        chunk_type :: size(32),
                        chunk_data :: binary - size(length),
                        crc :: size(32),
                        chunks :: binary>>, png) do
    chunk = %{length: length, chunk_type: chunk_type, data: chunk_data, crc: crc}
    png = %{png | chunks: [chunk | png.chunks]}

    png_parse_chunks(chunks, png)
  end

  defp png_parse_chunks(<<>>, png) do
    %{png | chunks: Enum.reverse(png.chunks)}
  end
end