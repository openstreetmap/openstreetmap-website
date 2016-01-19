class ChangesetComment < ActiveRecord::Base
  belongs_to :changeset
  belongs_to :author, :class_name => "User"

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :changeset, :presence => true, :associated => true
  validates :author, :presence => true, :associated => true
  validates :visible, :inclusion => [true, false]
  validates :body, :format => /\A[^\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff]*\z/

  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
