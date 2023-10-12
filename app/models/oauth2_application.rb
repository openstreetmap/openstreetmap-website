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
