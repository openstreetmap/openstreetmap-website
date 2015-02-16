##
# Encodes and decodes locations from Morton-coded "quad tile" strings. Each
# variable-length string encodes to a precision of one pixel per tile (roughly,
# since this computation is done in lat/lon coordinates, not mercator).
# Each character encodes 3 bits of x and 3 of y, so there are extra characters
# tacked on the end to make the zoom levels "work".
module ShortLink
  # array of 64 chars to encode 6 bits. this is almost like base64 encoding, but
  # the symbolic chars are different, as base64's + and / aren't very
  # URL-friendly.
  ARRAY = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a + ['_', '~']

  ##
  # Given a string encoding a location, returns the [lon, lat, z] tuple of that
  # location.
  def self.decode(str)
    x = 0
    y = 0
    z = 0
    z_offset = 0

    # keep support for old shortlinks which use the @ character, now
    # replaced by the ~ character because twitter is horribly broken
    # and we can't have that.
    str.gsub!("@", "~")

    str.each_char do |c|
      t = ARRAY.index c
      if t.nil?
        z_offset -= 1
      else
        3.times do
          x <<= 1; x |= 1 unless (t & 32).zero?; t <<= 1
          y <<= 1; y |= 1 unless (t & 32).zero?; t <<= 1
        end
        z += 3
      end
    end
    # pack the coordinates out to their original 32 bits.
    x <<= (32 - z)
    y <<= (32 - z)

    # project the parameters back to their coordinate ranges.
    [(x * 360.0 / 2**32) - 180.0,
     (y * 180.0 / 2**32) - 90.0,
     z - 8 - (z_offset % 3)]
  end

  ##
  # given a location and zoom, return a short string representing it.
  def self.encode(lon, lat, z)
    code = interleave_bits(((lon + 180.0) * 2**32 / 360.0).to_i,
                           ((lat +  90.0) * 2**32 / 180.0).to_i)
    str = ""
    # add eight to the zoom level, which approximates an accuracy of
    # one pixel in a tile.
    ((z + 8) / 3.0).ceil.times do |i|
      digit = (code >> (58 - 6 * i)) & 0x3f
      str << ARRAY[digit]
    end
    # append characters onto the end of the string to represent
    # partial zoom levels (characters themselves have a granularity
    # of 3 zoom levels).
    ((z + 8) % 3).times { str << "-" }

    str
  end

  private

  ##
  # interleaves the bits of two 32-bit numbers. the result is known
  # as a Morton code.
  def self.interleave_bits(x, y)
    c = 0
    31.downto(0) do |i|
      c = (c << 1) | ((x >> i) & 1)
      c = (c << 1) | ((y >> i) & 1)
    end
    c
  end
end
