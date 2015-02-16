class UserBlock < ActiveRecord::Base
  validate :moderator_permissions

  belongs_to :user, :class_name => "User", :foreign_key => :user_id
  belongs_to :creator, :class_name => "User", :foreign_key => :creator_id
  belongs_to :revoker, :class_name => "User", :foreign_key => :revoker_id

  PERIODS = USER_BLOCK_PERIODS

  ##
  # scope to match active blocks
  def self.active
    where("needs_view or ends_at > ?", Time.now.getutc)
  end

  ##
  # return a renderable version of the reason text.
  def reason
    RichText.new(read_attribute(:reason_format), read_attribute(:reason))
  end

  ##
  # returns true if the block is currently active (i.e: the user can't
  # use the API).
  def active?
    needs_view || ends_at > Time.now.getutc
  end

  ##
  # revokes the block, allowing the user to use the API again. the argument
  # is the user object who is revoking the ban.
  def revoke!(revoker)
    update_attributes(
      :ends_at => Time.now.getutc,
      :revoker_id => revoker.id,
      :needs_view => false
    )
  end

  private

  ##
  # validate that only moderators are allowed to change the
  # block. this should be caught and dealt with in the controller,
  # but i've also included it here just in case.
  def moderator_permissions
    errors.add(:base, I18n.t('user_block.model.non_moderator_update')) if creator_id_changed? && !creator.moderator?
    errors.add(:base, I18n.t('user_block.model.non_moderator_revoke')) unless revoker_id.nil? || revoker.moderator?
  end
end
