module Api
  class VersionsController < ApiController
    authorize_resource :class => false

    around_action :api_call_handle_error, :api_call_timeout

    # Show the list of available API versions. This will replace the global
    # unversioned capabilities call in due course.
    def show
      @versions = Settings.api_versions
    end
  end
end
