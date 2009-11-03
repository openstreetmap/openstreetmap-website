require 'i18n/backend/simple'

module Globalize
  module Backend
    class Pluralizing < I18n::Backend::Simple
      def pluralize(locale, entry, count)
        return entry unless entry.is_a?(Hash) and count
        key = :zero if count == 0 && entry.has_key?(:zero)
        key ||= pluralizer(locale).call(count, entry)
        key = :other unless entry.has_key?(key)
        raise InvalidPluralizationData.new(entry, count) unless entry.has_key?(key)
        translation entry[key], :plural_key => key
      end

      def add_pluralizer(locale, pluralizer)
        pluralizers[locale.to_sym] = pluralizer
      end

      def pluralizer(locale)
        pluralizers[locale.to_sym] || default_pluralizer
      end

      protected
        def default_pluralizer
          pluralizers[:en]
        end

        def pluralizers
          @pluralizers ||= {
            :en => lambda { |count, entry|
              case count
                when 1 then :one
                else :other
              end
            },
            :ru => lambda { |count, entry|
              case count % 100
                when 11,12,13,14 then :many
                else case count % 10
                       when 1 then :one
                       when 2,3,4 then :few
                       when 5,6,7,8,9,0 then :many
                       else :other
                     end
              end
            },
            :sl => lambda { |count, entry|
              case count % 100
                when 1 then :one
                when 2 then :two
                when 3,4 then :few
                else :other
              end
            }
          }
        end

        # Overwrite this method to return something other than a String
        def translation(string, attributes)
          string
        end
    end
  end
end
