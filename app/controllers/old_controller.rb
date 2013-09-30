# this class pulls together the logic for all the old_* controllers
# into one place. as it turns out, the API methods for historical
# nodes, ways and relations are basically identical.
class OldController < ApplicationController
  require 'xml/libxml'

  skip_before_filter :verify_authenticity_token
  before_filter :setup_user_auth, :only => [ :history, :version ]
  before_filter :authorize, :only => [ :redact ]
  before_filter :authorize_moderator, :only => [ :redact ]
  before_filter :require_allow_write_api, :only => [ :redact ]
  before_filter :check_api_readable
  before_filter :check_api_writable, :only => [ :redact ]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout
  before_filter :lookup_old_element, :except => [ :history ]
  before_filter :lookup_old_element_versions, :only => [ :history ]

  def history
    # the .where() method used in the lookup_old_element_versions
    # call won't throw an error if no records are found, so we have 
    # to do that ourselves.
    raise OSM::APINotFoundError.new if @elements.empty?

    doc = OSM::API.new.get_xml_doc
    
    visible_elements = if show_redactions?
                         @elements
                       else
                         @elements.unredacted
                       end

    visible_elements.each do |element|
      doc.root << element.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if @old_element.redacted? and not show_redactions?
      render :text => "", :status => :forbidden

    else
      response.last_modified = @old_element.timestamp
      
      doc = OSM::API.new.get_xml_doc
      doc.root << @old_element.to_xml_node
        
      render :text => doc.to_s, :content_type => "text/xml"
    end
  end

  def redact
    redaction_id = params['redaction']
    unless redaction_id.nil?
      # if a redaction ID was specified, then set this element to
      # be redacted in that redaction.
      redaction = Redaction.find(redaction_id.to_i)
      @old_element.redact!(redaction)
      
    else
      # if no redaction ID was provided, then this is an unredact
      # operation.
      @old_element.redact!(nil)
    end
    
    # just return an empty 200 OK for success
    render :text => ""
  end

  private
  
  def show_redactions?
    @user and @user.moderator? and params[:show_redactions] == "true"
  end
end
