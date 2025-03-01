# == Schema Information
#
# Table name: diary_comments
#
#  id             :bigint           not null, primary key
#  diary_entry_id :bigint           not null
#  user_id        :bigint           not null
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
#  index_diary_comments_on_user_id_and_id  (user_id,id)
#
# Foreign Keys
#
#  diary_comments_diary_entry_id_fkey  (diary_entry_id => diary_entries.id)
#  diary_comments_user_id_fkey         (user_id => users.id)
#

class DiaryComment < ApplicationRecord
  belongs_to :user, :counter_cache => true
  belongs_to :diary_entry

  scope :visible, -> { where(:visible => true) }

  validates :body, :presence => true, :characters => true
  validates :diary_entry, :user, :associated => true

  after_save :spam_check

  def body
    RichText.new(self[:body_format], self[:body])
  end

  def notification_token(subscriber)
    sha256 = Digest::SHA256.new
    sha256 << Rails.application.key_generator.generate_key("openstreetmap/diary_comment")
    sha256 << id.to_s
    sha256 << subscriber.to_s
    Base64.urlsafe_encode64(sha256.digest)[0, 8]
  end

  private

  def spam_check
    user.spam_check
  end
end
