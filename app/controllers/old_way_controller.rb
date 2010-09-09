class OldWayController < ApplicationController
  require 'xml/libxml'

  before_filter :check_api_readable
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    way = Way.find(params[:id])
    
    doc = OSM::API.new.get_xml_doc
    
    way.old_ways.each do |old_way|
      doc.root << old_way.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if old_way = OldWay.where(:id => params[:id], :version => params[:version]).first
      response.last_modified = old_way.timestamp

      doc = OSM::API.new.get_xml_doc
      doc.root << old_way.to_xml_node

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :not_found
    end
  end
end
