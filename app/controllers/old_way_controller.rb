class OldWayController < ApplicationController
  require 'xml/libxml'

  skip_before_filter :verify_authenticity_token
  before_filter :setup_user_auth, :only => [ :history, :version ]
  before_filter :authorize, :only => [ :redact ]
  before_filter :authorize_moderator, :only => [ :redact ]
  before_filter :require_allow_write_api, :only => [ :redact ]
  before_filter :check_api_readable
  before_filter :check_api_writable, :only => [ :redact ]
  before_filter :lookup_old_way, :except => [ :history ]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    way = Way.find(params[:id].to_i)
    
    doc = OSM::API.new.get_xml_doc
    
    visible_ways = if @user and @user.moderator? and params[:show_redactions] == "true"
                     way.old_ways
                   else
                     way.old_ways.unredacted
                   end
    
    visible_ways.each do |old_way|
      doc.root << old_way.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if @old_way.redacted? and not (@user and @user.moderator? and params[:show_redactions] == "true")
      render :nothing => true, :status => :forbidden
    else

      response.last_modified = @old_way.timestamp
      
      doc = OSM::API.new.get_xml_doc
      doc.root << @old_way.to_xml_node
        
      render :text => doc.to_s, :content_type => "text/xml"
    end
  end

  def redact
    redaction_id = params['redaction']
    unless redaction_id.nil?
      # if a redaction ID was specified, then set this way to
      # be redacted in that redaction. (TODO: check that the
      # user doing the redaction owns the redaction object too)
      redaction = Redaction.find(redaction_id.to_i)
      @old_way.redact!(redaction)
      
    else
      # if no redaction ID was provided, then this is an unredact
      # operation.
      @old_way.redact!(nil)
    end
    
    # just return an empty 200 OK for success
    render :nothing => true
  end

  private
  
  def lookup_old_way
    @old_way = OldWay.where(:way_id => params[:id], :version => params[:version]).first
    if @old_way.nil?
      render :nothing => true, :status => :not_found
      return false
    end
  end
end
