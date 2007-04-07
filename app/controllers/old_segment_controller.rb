class OldSegmentController < ApplicationController

  def history
    response.headers["Content-Type"] = 'application/xml'
    segment = Segment.find(params[:id])

    unless segment
      render :nothing => true, :staus => 404
      return
    end

    doc = OSM::API.new.get_xml_doc

    segment.old_segments.each do |old_segment|
      doc.root << old_segment.to_xml_node
    end

    render :text => doc.to_s
  end
end
