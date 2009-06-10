# Slovenian translations for Ruby on Rails 
# by Štefan Baebler (stefan@baebler.net)

{ :'sl' => {

    # ActiveSupport
    :support => {
      :array => {
        :words_connector => ', ',
        :two_words_connector => ' in ',
        :last_word_connector => ' in ',
        :sentence_connector => 'in',
        :skip_last_comma => true      }
    },

    # Date
    :date => {
      :formats => {
        :default => "%d. %m. %Y",
        :short   => "%d %b",
        :long    => "%d. %B %Y",
      },
      :day_names         => %w{nedelja ponedeljek torek sreda četrtek petek sobota},
      :abbr_day_names    => %w{ned pon tor sre čet pet sob},
      :month_names       => %w{~ januar februar marec april maj junij julj avgust september oktober november december},
      :abbr_month_names  => %w{~ jan feb mar apr maj jun jul avg sep okt nov dec},
      :order             => [:day, :month, :year]
    },

    # Time
    :time => {
      :formats => {
        :default => "%a %d. %B %Y %H:%M %z",
        :short   => "%d. %m. %H:%M",
        :long    => "%A %d. %B %Y %H:%M",
	:time    => "%H:%M"

      },
      :am => 'dopoldne',
      :pm => 'popoldne'
    },

    # Numbers
    :number => {
      :format => {
        :precision => 3,
        :separator => '.',
        :delimiter => ','
      },
      :currency => {
        :format => {
          :unit => '€',
          :precision => 2,
          :format    => '%n %u',
          :separator => ",",
          :delimiter => " ",
        }
      },
      :human => {
        :format => {
          :precision => 1,
          :delimiter => ''
        },
       :storage_units => {
         :format => "%n %u",
         :units => {
           :byte => "B",
           :kb   => "kB",
           :mb   => "MB",
           :gb   => "GB",
           :tb   => "TB",
         }
       }
      },
      :percentage => {
        :format => {
          :delimiter => ''
        }
      },
      :precision => {
        :format => {
          :delimiter => ''
        }
      }
    },

    # Distance of time ... helper
    # NOTE: In Czech language, these values are different for the past and for the future. Preference has been given to past here.
    :datetime => {
      :distance_in_words => {
        :half_a_minute => 'pol minute',
        :less_than_x_seconds => {
          :one => 'manj kot sekundo',
          :other => 'manj kot {{count}} sekund'
        },
        :x_seconds => {
          :one => 'sekunda',
          :other => '{{count}} sekund'
        },
        :less_than_x_minutes => {
          :one => 'manj kot minuto',
          :other => 'manj kot {{count}} minut'
        },
        :x_minutes => {
          :one => 'minuta',
          :other => '{{count}} minut'
        },
        :about_x_hours => {
          :one => 'približno eno uro',
          :other => 'približno {{count}} ur'
        },
        :x_days => {
          :one => 'en dan',
          :other => '{{count}} dni'
        },
        :about_x_months => {
          :one => 'približno en mesec',
          :other => 'približno {{count}} mesecev'
        },
        :x_months => {
          :one => 'en mesec',
          :other => '{{count}} mesecev'
        },
        :about_x_years => {
          :one => 'približno eno leto',
          :other => 'približno {{count}} let'
        },
        :over_x_years => {
          :one => 'več kot eno leto',
          :other => 'več kot {{count}} let'
        }
      }
    },

  }
}
