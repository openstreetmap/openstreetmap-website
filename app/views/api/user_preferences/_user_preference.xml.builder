# frozen_string_literal: true

attrs = {
  "k" => user_preference.k,
  "v" => user_preference.v
}

xml.preference(attrs)
