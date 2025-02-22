# == Schema Information
#
# Table name: oauth_applications
#
#  id           :bigint           not null, primary key
#  owner_type   :string           not null
#  owner_id     :bigint           not null
#  name         :string           not null
#  uid          :string           not null
#  secret       :string           not null
#  redirect_uri :text             not null
#  scopes       :string           default(""), not null
#  confidential :boolean          default(TRUE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_oauth_applications_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_oauth_applications_on_uid                      (uid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
class Oauth2Application < Doorkeeper::Application
  belongs_to :owner, :polymorphic => true

  validate :allowed_scopes

  def authorized_scopes_for(user)
    authorized_tokens.where(:resource_owner_id => user).sum(Doorkeeper::OAuth::Scopes.new, &:scopes)
  end

  private

  def allowed_scopes
    return if owner.administrator?

    errors.add(:scopes) if scopes.any? { |scope| Oauth::PRIVILEGED_SCOPES.include?(scope) }
  end
end
