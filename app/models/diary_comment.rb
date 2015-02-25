class DiaryComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :diary_entry

  validates :body, :presence => true
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
