# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include LibXML

  self.abstract_class = true
end
