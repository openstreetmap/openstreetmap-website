class OldNodeController < ApplicationController
  require 'xml/libxml'

  before_filter :check_api_readable
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    node = Node.find(params[:id])
    
    doc = OSM::API.new.get_xml_doc
    
    node.old_nodes.each do |old_node|
      doc.root << old_node.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if old_node = OldNode.where(:node_id => params[:id], :version => params[:version]).first
      response.last_modified = old_node.timestamp

      doc = OSM::API.new.get_xml_doc
      doc.root << old_node.to_xml_node

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :not_found
    end
  end
end
