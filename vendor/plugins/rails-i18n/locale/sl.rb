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
    # TODO: Needs proper pluralization formula: (n%100==1 ? one : n%100==2 ? two : n%100==3 || n%100==4 ? few : other)
    # NOTE: focused on "time ago" as in  "2 minuti nazaj", "3 tedne nazaj" which can be used also in other time distances 
    #       ("pred 2 minutama" isn't as universally usable.)
    :datetime => {
      :distance_in_words => {
        :half_a_minute => 'pol minute',
        :less_than_x_seconds => {
          :one => 'manj kot sekunda',
          :two => 'manj kot dve sekundi',
          :few => 'manj kot {{count}} sekunde',
          :other => 'manj kot {{count}} sekund'
        },
        :x_seconds => {
          :one => 'sekunda',
          :two => 'dve sekundi',
          :few => '{{count}} sekunde',
          :other => '{{count}} sekund'
        },
        :less_than_x_minutes => {
          :one => 'manj kot minuta',
          :two => 'manj kot dve minuti',
          :few => 'manj kot {{count}} minute',
          :other => 'manj kot {{count}} minut'
        },
        :x_minutes => {
          :one => 'minuta',
          :two => 'dve minuti',
          :few => '{{count}} minute',
          :other => '{{count}} minut'
        },
        :about_x_hours => {
          :one => 'približno ena ura',
          :two => 'približno dve uri',
          :few => 'približno {{count}} ure',
          :other => 'približno {{count}} ur'
        },
        :x_days => {
          :one => 'en dan',
          :two => 'dva dni',
          :few => '{{count}} dni',
          :other => '{{count}} dni'
        },
        :about_x_months => {
          :one => 'približno en mesec',
          :two => 'približno dva meseca',
          :few => 'približno {{count}} mesece',
          :other => 'približno {{count}} mesecev'
        },
        :x_months => {
          :one => 'en mesec',
          :two => 'dva meseca',
          :few => '{{count}} meseci',
          :other => '{{count}} mesecev'
        },
        :about_x_years => {
          :one => 'približno {{count}} leto',
          :two => 'približno {{count}} leti',
          :few => 'približno {{count}} leta',
          :other => 'približno {{count}} let'
        },
        :over_x_years => {
          :one => 'več kot {{count}} leto',
          :two => 'več kot {{count}} leti',
          :few => 'več kot {{count}} leta',
          :other => 'več kot {{count}} let'
        }
      }
    },

    # ActiveRecord validation messages
    :activerecord => {
      :errors => {
        :messages => {
          :inclusion           => "ni v seznamu",
          :exclusion           => "ni dostopno",
          :invalid             => "ni veljavno",
          :confirmation        => "ni skladno s potrditvijo",
          :accepted            => "mora biti potrjeno",
          :empty               => "ne sme biti prazno",
          :blank               => "je obezno", # alternate formulation: "is required"
          :too_long            => "je predolgo (največ {{count}} znakov)",
          :too_short           => "je prekratko (vsaj {{count}} znakov)",
          :wrong_length        => "ni pravilne dolžine (natanko {{count}} znakov)",
          :taken               => "že obstaja v bazi",
          :not_a_number        => "ni številka",
          :greater_than        => "mora biti večje od {{count}}",
          :greater_than_or_equal_to => "mora biti večje ali enako {{count}}",
          :equal_to            => "mora biti enako {{count}}",
          :less_than           => "mora biti manjše od {{count}}",
          :less_than_or_equal_to    => "mora biti manjše ali enako {{count}}",
          :odd                 => "mora biti liho",
          :even                => "mora biti sodo"
        },
        :template => {
          :header   => {
            :one => "Pri shranjevanju predmeta {{model}} je prišlo do {{count}} napake",
            :other => "Pri shranjevanju predmeta {{model}} je prišlo do {{count}} napak"
          },
          :body  => "Prosim, popravite naslednje napake posameznih polj:"
        }
      }
    }
  }
}
