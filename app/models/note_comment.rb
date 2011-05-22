class NoteComment < ActiveRecord::Base
  belongs_to :note, :foreign_key => :note_id
  belongs_to :author, :class_name => "User", :foreign_key => :author_id

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_presence_of :note_id
  validates_associated :note
  validates_presence_of :visible
  validates_associated :author
  validates_inclusion_of :event, :in => [ "opened", "closed", "reopened", "commented", "hidden" ]

  # Return the author name
  def author_name
    if self.author_id.nil?
      self.read_attribute(:author_name)
    else
      self.author.display_name
    end
  end
end
