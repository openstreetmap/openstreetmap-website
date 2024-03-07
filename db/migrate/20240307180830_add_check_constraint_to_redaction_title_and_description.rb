class AddCheckConstraintToRedactionTitleAndDescription < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Redaction.where(:title => nil).find_in_batches(:batch_size => 1000) do |redactions|
      redactions.each do |r|
        r.title = "Redaction #{r.id}"
        r.save!(:validate => false)
      end
    end

    Redaction.where(:description => nil).find_in_batches(:batch_size => 1000) do |redactions|
      redactions.each { |r| r.update!(:description => "No description") }
    end

    add_check_constraint :redactions, "title IS NOT NULL", :name => "redaction_title_not_null", :validate => false
    add_check_constraint :redactions, "description IS NOT NULL", :name => "redaction_description_not_null", :validate => false
  end

  def down
    remove_check_constraint :redactions, :name => "redaction_title_not_null", :if_exists => true
    remove_check_constraint :redactions, :name => "redaction_description_not_null", :if_exists => true
  end
end
