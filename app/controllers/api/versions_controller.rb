module Api
  class VersionsController < ApiController
    skip_before_action :check_api_readable
    authorize_resource :class => false

    before_action :set_request_formats

    # Show the list of available API versions. This will replace the global
    # unversioned capabilities call in due course.
    # Currently we only support deploying one version at a time, but this will
    # hopefully change soon.
    def show
      @versions = [Settings.api_version]
    end
  end
end
