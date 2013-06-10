class NoteComment < ActiveRecord::Base
  belongs_to :note, :foreign_key => :note_id, :touch => true
  belongs_to :author, :class_name => "User", :foreign_key => :author_id

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_presence_of :note_id
  validates_associated :note
  validates_presence_of :visible
  validates_associated :author
  validates_inclusion_of :event, :in => [ "opened", "closed", "reopened", "commented", "hidden" ]

  # Return the comment text
  def body
    RichText.new("text", read_attribute(:body))
  end
end
