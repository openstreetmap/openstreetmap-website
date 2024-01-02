# == Schema Information
#
# Table name: languages
#
#  code         :string           not null, primary key
#  english_name :string           not null
#  native_name  :string
#

class Language < ApplicationRecord
  has_many :diary_entries, :foreign_key => "language", :inverse_of => :language

  def self.load(file)
    Language.transaction do
      YAML.safe_load_file(file).each do |k, v|
        Language.update(k, :english_name => v["english"], :native_name => v["native"])
      rescue ActiveRecord::RecordNotFound
        Language.create do |l|
          l.code = k
          l.english_name = v["english"]
          l.native_name = v["native"]
        end
      end
    end
  end

  def name
    name = english_name
    name += " (#{native_name})" unless native_name.nil? || native_name == english_name
    name
  end
end
