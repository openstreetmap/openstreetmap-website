xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title "OpenStreetBugs"
    xml.description t('bugs.rss.description_item', :id => @bug.id)
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)

    xml << render(:partial => "bug", :object => @bug)
  end
end
