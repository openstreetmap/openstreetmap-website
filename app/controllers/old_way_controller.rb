class OldWayController < ApplicationController
  require 'xml/libxml'

  skip_before_filter :verify_authenticity_token
  before_filter :authorize, :only => [ :redact ]
  before_filter :require_allow_write_api, :only => [ :redact ]
  before_filter :check_api_readable
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    way = Way.find(params[:id])

    # TODO - maybe a bit heavyweight to do this on every
    # call, perhaps try lazy auth.
    setup_user_auth
    
    doc = OSM::API.new.get_xml_doc
    
    way.old_ways.each do |old_way|
      unless old_way.redacted? and (@user.nil? or not @user.moderator?) and not params[:show_redactions] == "true"
        doc.root << old_way.to_xml_node
      end
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if old_way = OldWay.where(:way_id => params[:id], :version => params[:version]).first
      # TODO - maybe a bit heavyweight to do this on every
      # call, perhaps try lazy auth.
      setup_user_auth

      if old_way.redacted? and (@user.nil? or not @user.moderator?) and not params[:show_redactions] == "true"
        render :nothing => true, :status => :forbidden
      else
        response.last_modified = old_way.timestamp
        
        doc = OSM::API.new.get_xml_doc
        doc.root << old_way.to_xml_node
        
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
