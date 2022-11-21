# this class pulls together the logic for all the old_* controllers
# into one place. as it turns out, the API methods for historical
# nodes, ways and relations are basically identical.
module Api
  class OldController < ApiController
    require "xml/libxml"

    before_action :check_api_readable
    before_action :check_api_writable, :only => [:redact]
    before_action :setup_user_auth, :only => [:history, :version]
    before_action :authorize, :only => [:redact]

    authorize_resource

    around_action :api_call_handle_error, :api_call_timeout
    before_action :lookup_old_element, :except => [:history]
    before_action :lookup_old_element_versions, :only => [:history]

    before_action :set_request_formats, :except => [:redact]

    def history
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

    def version
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

    def redact
      redaction_id = params["redaction"]
      if redaction_id.nil?
        # if no redaction ID was provided, then this is an unredact
        # operation.
        @old_element.redact!(nil)
      else
        # if a redaction ID was specified, then set this element to
        # be redacted in that redaction.
        redaction = Redaction.find(redaction_id.to_i)
        @old_element.redact!(redaction)
      end

      # just return an empty 200 OK for success
      head :ok
    end

    private

    def show_redactions?
      current_user&.moderator? && params[:show_redactions] == "true"
    end
  end
end
