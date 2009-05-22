class Language < ActiveRecord::Base
  set_primary_key :language_code
  
  has_many :users, :foreign_key => 'locale'
  has_many :diary_entries, :foreign_key => 'language'
end
