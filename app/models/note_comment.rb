class NoteComment < ActiveRecord::Base
  belongs_to :note, :foreign_key => :note_id, :touch => true
  belongs_to :author, :class_name => "User", :foreign_key => :author_id

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :note, :presence => true, :associated => true
  validates :visible, :inclusion => [true, false]
  validates :author, :associated => true
  validates :event, :inclusion => %w(opened closed reopened commented hidden)
  validates :body, :format => /\A[^\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff]*\z/

  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
