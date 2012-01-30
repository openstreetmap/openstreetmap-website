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

  class Message
    def decoded_with_text
      if self.text?
        decode_body_as_text
      else
        decoded_without_text
      end
    end

    alias_method_chain :decoded, :text

    def text?
      has_content_type? ? !!(main_type =~ /^text$/i) : false
    end

  private

    def decode_body_as_text
      body_text = body.decoded
      if charset
        if RUBY_VERSION < '1.9'
          require 'iconv'
          return Iconv.conv("UTF-8//TRANSLIT//IGNORE", charset, body_text)
        else
          if encoding = Encoding.find(charset) rescue nil
            body_text.force_encoding(encoding)
            return body_text.encode(Encoding::UTF_8)
          end
        end
      end
      body_text
    end    
  end
end
