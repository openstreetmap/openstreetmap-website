class Language < ActiveRecord::Base
  set_primary_key :code

  has_many :users, :foreign_key => 'locale'
  has_many :diary_entries, :foreign_key => 'language'
  
  def self.generate(code, name, translation_available)
    Language.create do |l|
      l.code = code
      l.name = name
      l.translation_available = translation_available
    end
  end
end
