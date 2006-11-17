class ApiController < ApplicationController

  def map


    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root

    render :text => doc.to_s
    
    #el1 = XML::Node.new 'node'
    #el1['id'] = self.id.to_s
    #el1['lat'] = self.latitude.to_s
    #el1['lon'] = self.longitude.to_s
    #Node.split_tags(el1, self.tags)
    #el1['visible'] = self.visible.to_s
    #el1['timestamp'] = self.timestamp.xmlschema
    #root << el1
  end



end
