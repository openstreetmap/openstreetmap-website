class NameUnnamedRedactions < ActiveRecord::Migration[5.0]
  def self.up
    change_column_null "redactions", "title", false
    Redaction.find_each do |redaction|
      if redaction.title.empty?
        redaction.title = redaction.id.to_s
        redaction.save!
      end
    end
  end

  def self.down
    change_column_null "redactions", "title", true
  end
end
