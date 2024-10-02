module Api
  class PermissionsController < ApiController
    authorize_resource :class => false

    before_action :setup_user_auth
    before_action :set_request_formats

    # External apps that use the api are able to query which permissions
    # they have. This currently returns a list of permissions granted to the current user:
    # * if authenticated via OAuth, this list will contain all permissions granted by the user to the access_token.
    # * unauthenticated users have no permissions, so the list will be empty.
    def show
      @permissions = if doorkeeper_token.present?
                       doorkeeper_token.scopes.map { |s| :"allow_#{s}" }
                     else
                       []
                     end

      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
