class NoteComment < ActiveRecord::Base
  belongs_to :note, :foreign_key => :bug_id
  belongs_to :author, :class_name => "User", :foreign_key => :author_id

  validates_inclusion_of :event, :in => [ "opened", "closed", "reopened", "commented", "hidden" ]
  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_presence_of :visible

  def author_name
    if self.author_id.nil?
      self.read_attribute(:author_name)
    else
      self.author.display_name
    end
  end
end
