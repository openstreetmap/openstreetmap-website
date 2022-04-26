module Api
  class PermissionsController < ApiController
    before_action :check_api_readable

    authorize_resource :class => false

    before_action :setup_user_auth
    before_action :set_request_formats
    around_action :api_call_handle_error, :api_call_timeout

    # External apps that use the api are able to query which permissions
    # they have. This currently returns a list of permissions granted to the current user:
    # * if authenticated via OAuth, this list will contain all permissions granted by the user to the access_token.
    # * if authenticated via basic auth all permissions are granted, so the list will contain all permissions.
    # * unauthenticated users have no permissions, so the list will be empty.
    def show
      @permissions = if doorkeeper_token.present?
                       doorkeeper_token.scopes.map { |s| :"allow_#{s}" }
                     elsif current_token.present?
                       ClientApplication.all_permissions.select { |p| current_token.read_attribute(p) }
                     elsif current_user
                       ClientApplication.all_permissions
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
