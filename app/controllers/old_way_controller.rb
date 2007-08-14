class OldWayController < ApplicationController
  require 'xml/libxml'

  session :off
  after_filter :compress_output

  def history
    begin
      way = Way.find(params[:id])
    
      doc = OSM::API.new.get_xml_doc

      way.old_ways.each do |old_way|
        doc.root << old_way.to_xml_node
     end

      render :text => doc.to_s, :content_type => "text/xml"
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end
end
