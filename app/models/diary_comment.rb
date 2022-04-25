# == Schema Information
#
# Table name: diary_comments
#
#  id             :bigint(8)        not null, primary key
#  diary_entry_id :bigint(8)        not null
#  user_id        :bigint(8)        not null
#  body           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  visible        :boolean          default(TRUE), not null
#  body_format    :enum             default("markdown"), not null
#
# Indexes
#
#  diary_comment_user_id_created_at_index  (user_id,created_at)
#  diary_comments_entry_id_idx             (diary_entry_id,id) UNIQUE
#
# Foreign Keys
#
#  diary_comments_diary_entry_id_fkey  (diary_entry_id => diary_entries.id)
#  diary_comments_user_id_fkey         (user_id => users.id)
#

class DiaryComment < ApplicationRecord
  belongs_to :user
  belongs_to :diary_entry

  scope :visible, -> { where(:visible => true) }

  validates :body, :presence => true, :characters => true
  validates :diary_entry, :user, :associated => true

  after_save :spam_check

  def body
    RichText.new(self[:body_format], self[:body])
  end

  def digest
    md5 = Digest::MD5.new
    md5 << diary_entry_id.to_s
    md5 << user_id.to_s
    md5 << created_at.xmlschema
    md5 << body
    md5.hexdigest
  end

  private

  def spam_check
    user.spam_check
  end
end
