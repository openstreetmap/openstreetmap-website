class Oauth2Application < Doorkeeper::Application
  belongs_to :owner, :polymorphic => true

  validate :allowed_scopes

  private

  def allowed_scopes
    return if owner.administrator?

    errors.add(:scopes) if scopes.any? { |scope| Oauth::PRIVILEGED_SCOPES.include?(scope) }
  end
end
