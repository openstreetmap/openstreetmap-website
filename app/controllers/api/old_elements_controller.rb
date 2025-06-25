# this class pulls together the logic for all the old_* controllers
# into one place. as it turns out, the API methods for historical
# nodes, ways and relations are basically identical.
module Api
  class OldElementsController < ApiController
    before_action :setup_user_auth

    authorize_resource

    before_action :lookup_old_element, :except => [:index]
    before_action :lookup_old_element_versions, :only => [:index]

    before_action :set_request_formats

    def index
      # the .where() method used in the lookup_old_element_versions
      # call won't throw an error if no records are found, so we have
      # to do that ourselves.
      raise OSM::APINotFoundError if @elements.empty?

      # determine visible elements
      @elems = if show_redactions?
                 @elements
               else
                 @elements.unredacted
               end

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end

    def show
      if @old_element.redacted? && !show_redactions?
        head :forbidden

      else
        response.last_modified = @old_element.timestamp

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end

    private

    def show_redactions?
      current_user&.moderator? && params[:show_redactions] == "true"
    end
  end
end
