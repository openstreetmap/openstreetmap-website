class OldNodeController < ApplicationController
  require 'xml/libxml'

  skip_before_filter :verify_authenticity_token
  before_filter :setup_user_auth, :only => [ :history, :version ]
  before_filter :authorize, :only => [ :redact ]
  before_filter :authorize_moderator, :only => [ :redact ]
  before_filter :require_allow_write_api, :only => [ :redact ]
  before_filter :check_api_readable
  before_filter :check_api_writable, :only => [ :redact ]
  before_filter :lookup_old_node, :except => [ :history ]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    node = Node.find(params[:id].to_i)
    
    doc = OSM::API.new.get_xml_doc
    
    visible_nodes = if @user and @user.moderator? and params[:show_redactions] == "true"
                      node.old_nodes
                    else
                      node.old_nodes.unredacted
                    end

    visible_nodes.each do |old_node|
      doc.root << old_node.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if @old_node.redacted? and (@user.nil? or not @user.moderator?) and not params[:show_redactions] == "true"
      render :nothing => true, :status => :forbidden

    else
      response.last_modified = @old_node.timestamp
      
      doc = OSM::API.new.get_xml_doc
      doc.root << @old_node.to_xml_node
        
      render :text => doc.to_s, :content_type => "text/xml"
    end
  end

  def redact
    redaction_id = params['redaction']
    unless redaction_id.nil?
      # if a redaction ID was specified, then set this node to
      # be redacted in that redaction. (TODO: check that the
      # user doing the redaction owns the redaction object too)
      redaction = Redaction.find(redaction_id.to_i)
      @old_node.redact!(redaction)
      
    else
      # if no redaction ID was provided, then this is an unredact
      # operation.
      @old_node.redact!(nil)
    end
    
    # just return an empty 200 OK for success
    render :nothing => true
  end

  private
  
  def lookup_old_node
    @old_node = OldNode.where(:node_id => params[:id], :version => params[:version]).first
    if @old_node.nil?
      # i want to do this
      #raise OSM::APINotFoundError.new
      # but i get errors, so i'm getting very fed up and doing this instead
      render :nothing => true, :status => :not_found
      return false
    end
  end
end
