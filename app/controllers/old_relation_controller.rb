class OldRelationController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :check_api_readable
  after_filter :compress_output

  def history
    begin
      relation = Relation.find(params[:id])
      doc = OSM::API.new.get_xml_doc

      relation.old_relations.each do |old_relation|
        doc.root << old_relation.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end
  
  def version
    begin
      old_relation = OldRelation.find(:first, :conditions => {:id => params[:id], :version => params[:version]} )
      
      response.headers['Last-Modified'] = old_relation.timestamp.rfc822

      doc = OSM::API.new.get_xml_doc
      doc.root << old_relation.to_xml_node

      render :text => doc.to_s, :content_type => "text/xml"
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end
end
