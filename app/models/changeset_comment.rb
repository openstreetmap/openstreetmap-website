# == Schema Information
#
# Table name: changeset_comments
#
#  id           :integer          not null, primary key
#  changeset_id :bigint(8)        not null
#  author_id    :bigint(8)        not null
#  body         :text             not null
#  created_at   :datetime         not null
#  visible      :boolean          not null
#
# Indexes
#
#  index_changeset_comments_on_created_at  (created_at)
#
# Foreign Keys
#
#  changeset_comments_author_id_fkey     (author_id => users.id)
#  changeset_comments_changeset_id_fkey  (changeset_id => changesets.id)
#

class ChangesetComment < ActiveRecord::Base
  belongs_to :changeset
  belongs_to :author, :class_name => "User"

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :changeset, :presence => true, :associated => true
  validates :author, :presence => true, :associated => true
  validates :visible, :inclusion => [true, false]
  validates :body, :characters => true

  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
