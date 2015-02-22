module UTF8
  ##
  # Checks that a string is valid UTF-8 by trying to convert it to UTF-8
  # using the iconv library, which is in the standard library.
  def self.valid?(str)
    return true if str.nil?
    str.valid_encoding?
  end
end
