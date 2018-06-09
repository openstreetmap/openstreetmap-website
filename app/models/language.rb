# == Schema Information
#
# Table name: languages
#
#  code         :string           not null, primary key
#  english_name :string           not null
#  native_name  :string
#

class Language < ActiveRecord::Base
  self.primary_key = "code"

  has_many :diary_entries, :foreign_key => "language"

  def self.load(file)
    Language.transaction do
      YAML.safe_load(File.read(file)).each do |k, v|
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
    name += " (#{native_name})" unless native_name.nil?
    name
  end
end
