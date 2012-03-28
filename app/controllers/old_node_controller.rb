class OldNodeController < ApplicationController
  require 'xml/libxml'

  skip_before_filter :verify_authenticity_token
  before_filter :authorize, :only => [ :redact ]
  before_filter :require_allow_write_api, :only => [ :redact ]
  before_filter :check_api_readable
  before_filter :check_api_writable, :only => [ :redact ]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    # TODO - maybe a bit heavyweight to do this on every
    # call, perhaps try lazy auth.
    setup_user_auth

    node = Node.find(params[:id].to_i)
    
    doc = OSM::API.new.get_xml_doc
    
    node.old_nodes.each do |old_node|
      unless old_node.redacted? and (@user.nil? or not @user.moderator?)
        doc.root << old_node.to_xml_node
      end
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if old_node = OldNode.where(:node_id => params[:id], :version => params[:version]).first
      # TODO - maybe a bit heavyweight to do this on every
      # call, perhaps try lazy auth.
      setup_user_auth
      
      if old_node.redacted? and (@user.nil? or not @user.moderator?)
        render :nothing => true, :status => :forbidden
      else

        response.last_modified = old_node.timestamp
        
        doc = OSM::API.new.get_xml_doc
        doc.root << old_node.to_xml_node
        
        render :text => doc.to_s, :content_type => "text/xml"
      end
    else
      render :nothing => true, :status => :not_found
    end
  end

  def redact
    if @user && @user.moderator?
      render :nothing => true

    else
      render :nothing => true, :status => :forbidden
    end
  end
end
