class NameUnnamedRedactions < ActiveRecord::Migration[5.0]
  def self.up
    Redaction.find_each do |redaction|
        if redaction.title.empty?
            redaction.title = redaction.id.to_s
            redaction.save!
        end
    end
  end

  def self.down
    Redaction.find_each do |redaction|
        if redaction.title.eql? redaction.id.to_s
            redaction.title = ""
            redaction.save!
        end
    end
  end
end
