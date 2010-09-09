class OldRelationController < ApplicationController
  require 'xml/libxml'

  before_filter :check_api_readable
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  def history
    relation = Relation.find(params[:id])
    doc = OSM::API.new.get_xml_doc
    
    relation.old_relations.each do |old_relation|
      doc.root << old_relation.to_xml_node
    end
    
    render :text => doc.to_s, :content_type => "text/xml"
  end
  
  def version
    if old_relation = OldRelation.where(:id => params[:id], :version => params[:version]).first
      response.headers['Last-Modified'] = old_relation.timestamp.rfc822

      doc = OSM::API.new.get_xml_doc
      doc.root << old_relation.to_xml_node

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :not_found
    end
  end
end
