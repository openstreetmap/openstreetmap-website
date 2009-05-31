class Language < ActiveRecord::Base
  set_primary_key :code

  has_many :diary_entries, :foreign_key => 'language'

  def name
    name = english_name
    name += " (#{native_name})" unless native_name.nil?
    name
  end  
end
