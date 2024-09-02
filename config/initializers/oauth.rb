require "oauth/helper"

module OAuth
  module Helper
    def escape(value)
      value.to_s.gsub(OAuth::RESERVED_CHARACTERS) do |c|
        c.bytes.map do |b|
          format("%%%02X", b)
        end.join
      end.force_encoding(Encoding::US_ASCII)
    end

    def unescape(value)
      value.to_s.gsub(/%\h{2}/) do |c|
        c[1..].to_i(16).chr
      end.force_encoding(Encoding::UTF_8)
    end
  end
end
