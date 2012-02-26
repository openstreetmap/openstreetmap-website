module Mail
  class Ruby18
    def Ruby18.b_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Bb]\?(.+)?\?\=/m)
      if match
        encoding = match[1]
        str = Ruby18.decode_base64(match[2])
        require 'iconv'
        str = Iconv.conv("UTF-8//TRANSLIT//IGNORE", encoding, str)
      end
      str
    end

    def Ruby18.q_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Qq]\?(.+)?\?\=/m)
      if match
        encoding = match[1]
        str = Encodings::QuotedPrintable.decode(match[2].gsub(/_/, '=20'))
        require 'iconv'
        str = Iconv.conv("UTF-8//TRANSLIT//IGNORE", encoding, str)
      end
      str
    end
  end
end
