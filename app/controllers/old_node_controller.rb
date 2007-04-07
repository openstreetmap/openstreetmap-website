class OldNodeController < ApplicationController

  def history
    response.headers["Content-Type"] = 'application/xml'
    node = Node.find(params[:id])

    unless node
      render :nothing => true, :staus => 404
      return
    end

    doc = OSM::API.new.get_xml_doc

    node.old_nodes.each do |old_node|
      doc.root << old_node.to_xml_node
    end

    render :text => doc.to_s
  end


end
