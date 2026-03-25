# frozen_string_literal: true

class GpsRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :gps, reading: :gps }
end
