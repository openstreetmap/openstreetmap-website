{
  :ar => {
    :i18n => {
      :plural => {
        :rule => lambda { |count|
          case count
            when 1 then :one
            when 2 then :two
            else case count % 100
                   when 3..10 then :few
                   when 11..99 then :many
                   else :other
                 end
          end
        } 
      }
    }
  },
  :ru => {
    :i18n => {
      :plural => {
        :rule => lambda { |count|
          case count % 100
            when 11,12,13,14 then :many
            else case count % 10
                   when 1 then :one
                   when 2,3,4 then :few
                   when 5,6,7,8,9,0 then :many
                   else :other
                 end
          end
        }
      }
    }
  },
  :sl => {
    :i18n => {
      :plural => {
        :rule => lambda { |count|
          case count % 100
            when 1 then :one
            when 2 then :two
            when 3,4 then :few
            else :other
          end
        }
      }
    }
  }
}
