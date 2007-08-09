class OldSegmentController < ApplicationController
  require 'xml/libxml'

  after_filter :compress_output

  def history
    begin
      segment = Segment.find(params[:id])

      doc = OSM::API.new.get_xml_doc

      segment.old_segments.each do |old_segment|
        doc.root << old_segment.to_xml_node
      end

     render :text => doc.to_s, :content_type => "text/xml"
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end
end
