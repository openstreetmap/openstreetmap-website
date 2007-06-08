class OldWayController < ApplicationController
  def history
    response.headers["Content-Type"] = 'text/xml'
    way = Way.find(params[:id])

    unless way
      render :nothing => true, :staus => 404
      return
    end
    
    doc = OSM::API.new.get_xml_doc

    way.old_ways.each do |old_way|
      doc.root << old_way.to_xml_node
    end

    render :text => doc.to_s
  end


end
