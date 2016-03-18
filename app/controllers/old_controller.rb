# this class pulls together the logic for all the old_* controllers
# into one place. as it turns out, the API methods for historical
# nodes, ways and relations are basically identical.
class OldController < ApplicationController
  require "xml/libxml"

  skip_before_action :verify_authenticity_token
  before_action :setup_user_auth, :only => [:history, :version]
  before_action :authorize, :only => [:redact]
  before_action :authorize_moderator, :only => [:redact]
  before_action :require_allow_write_api, :only => [:redact]
  before_action :check_api_readable
  before_action :check_api_writable, :only => [:redact]
  around_action :api_call_handle_error, :api_call_timeout
  before_action :lookup_old_element, :only => [:version, :redact]
  before_action :lookup_old_element_versions, :only => [:history]
  before_action :lookup_old_elements, :only => [:elements]

  def history
    # the .where() method used in the lookup_old_element_versions
    # call won't throw an error if no records are found, so we have
    # to do that ourselves.
    raise OSM::APINotFoundError.new if @elements.empty?

    visible_elements = if show_redactions?
                         @elements
                       else
                         @elements.unredacted
                       end
    print_elements(visible_elements)
  end

  def elements
    print_elements(@elements.select { |i| i.redaction_id.nil? })
  end

  def parse_old_elements(param_key)
    unless params[param_key] && params[param_key].match(/\d+v\d+(,\d+v\d+)*/)
      raise OSM::APIBadUserInput.new("The parameter #{param_key} is required, and must be of the form #{param_key}={id}v{version}[,...]")
    end
    params[param_key].split(",").collect do |id|
      id.split("v", 2).collect(&:to_i) # id and version
    end
  end

  def print_elements(visible_elements)
    doc = OSM::API.new.get_xml_doc
    visible_elements.each do |element|
      doc.root << element.to_xml_node
    end

    render :text => doc.to_s, :content_type => "text/xml"
  end

  def version
    if @old_element.redacted? && !show_redactions?
      render :text => "", :status => :forbidden

    else
      response.last_modified = @old_element.timestamp

      doc = OSM::API.new.get_xml_doc
      doc.root << @old_element.to_xml_node

      render :text => doc.to_s, :content_type => "text/xml"
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
    render :text => ""
  end

  private

  def show_redactions?
    @user && @user.moderator? && params[:show_redactions] == "true"
  end
end
