# frozen_string_literal: true

class WidthValidator < ActiveModel::Validations::LengthValidator
  # Codepoints that take up a column but don't show anything
  BLANK_CODEPOINTS = /
    \p{White_Space} |
    \p{Control} |
    \p{Unassigned} |
    \p{Private_Use} |
    \p{Default_Ignorable_Code_Point} |
    \u{2800} | # BRAILLE PATTERN BLANK
    \u{1D159}  # MUSICAL SYMBOL NULL NOTEHEAD
  /x

  module WidthAsLength
    def length
      Unicode::DisplayWidth.of(to_s.gsub(BLANK_CODEPOINTS, ""))
    end
  end

  def validate_each(record, attribute, value)
    super(record, attribute, value.extend(WidthAsLength))
  end
end
