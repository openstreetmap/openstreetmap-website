class OldElementsController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  before_action :require_moderator_for_unredacted_history
  around_action :web_timeout

  private

  def require_moderator_for_unredacted_history
    deny_access(nil) if params[:show_redactions] && !current_user&.moderator?
  end
end
