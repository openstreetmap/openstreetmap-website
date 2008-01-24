# Note that this file is currently unused
# I (xin@zxv.ltd.uk) suspect this is slower than using OSM module, which in turn uses libxml
# it will be good to output xml this way eventually.
xml.instruct! :xml, :version=>"1.0"
xml.osm("version" => "0.5", "generator" => "OpenStreetMap Server") do
  @nodes.each do |node|
    xml.tag! "node",:id => node.id,
                    :lat => node.lat,
                    :lon => node.lon,
                    :user => node.user_display_name,
                    :visible => node.visible,
                    :timestamp => node.timestamp.xmlschema  do
      node.tags.each do |tag|
        k,v = tag.split('=')
        xml.tag! "tag",:k => k, :v => v
      end
    end
  end
  @ways.each do |way|
    xml.tag! "way", :id => way.id,
                    :user => way.user_display_name,
                    :visible => way.visible,
                    :timestamp => way.timestamp.xmlschema  do
      way.nds.each do |nd|
        xml.tag! "nd", :ref => nd
      end

    end
      
    
  end
end
