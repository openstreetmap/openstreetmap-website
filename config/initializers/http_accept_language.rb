#
# Monkey patch HttpAcceptLanguage pending integration of
# https://github.com/iain/http_accept_language/pull/6
#
module HttpAcceptLanguage
  class Parser
    def compatible_language_from(available_languages)
      user_preferred_languages.find do |x|
        available_languages.find { |y| y.to_s == x.to_s } ||
          available_languages.find { |y| y.to_s =~ /^#{Regexp.escape(x.to_s)}-/ }
      end
    end
  end
end
