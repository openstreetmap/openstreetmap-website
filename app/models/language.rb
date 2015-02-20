class Language < ActiveRecord::Base
  self.primary_key = "code"

  has_many :diary_entries, :foreign_key => "language"

  def self.load(file)
    Language.transaction do
      YAML.load(File.read(file)).each do |k, v|
        begin
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
  end

  def name
    name = english_name
    name += " (#{native_name})" unless native_name.nil?
    name
  end
end
