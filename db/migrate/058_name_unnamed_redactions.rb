class NameUnnamedRedactions < ActiveRecord::Migration[5.0]
  def self.up
  	# after titles are fixed we change the column so to not be null
    change_column_null "redactions", "title", false
    # gets each redaction
    # sets redaction title equal to a string of the id if there is no title
    Redaction.find_each do |redaction|
      if redaction.title.empty?
        redaction.title = redaction.id.to_s
        redaction.save!
      end
    end
  end

  def self.down
  	# for down-migration we allow title column to be null
    change_column_null "redactions", "title", true
  end
end
