# frozen_string_literal: true

require "better_html/tree/tag"
require "active_support/core_ext/string/inflections"

module ERBLint
  module Linters
    # A customised version of the HardCodedString linter, adding `&middot;` as not needing translation
    # Checks for hardcoded strings. Useful if you want to ensure a string can be translated using i18n.
    class CustomHardCodedString < HardCodedString
      include LinterRegistry

      NO_TRANSLATION_NEEDED = Set.new([
                                        "&nbsp;",
                                        "&amp;",
                                        "&lt;",
                                        "&gt;",
                                        "&quot;",
                                        "&copy;",
                                        "&reg;",
                                        "&trade;",
                                        "&hellip;",
                                        "&mdash;",
                                        "&bull;",
                                        "&ldquo;",
                                        "&rdquo;",
                                        "&lsquo;",
                                        "&rsquo;",
                                        "&larr;",
                                        "&rarr;",
                                        "&darr;",
                                        "&uarr;",
                                        "&ensp;",
                                        "&emsp;",
                                        "&thinsp;",
                                        "&times;",
                                        "&laquo;",
                                        "&raquo;",
                                        "&middot;"
                                      ])

      private

      def check_string?(str)
        string = str.gsub(/\s*/, "")
        string.length > 1 && !NO_TRANSLATION_NEEDED.include?(string)
      end
    end
  end
end
