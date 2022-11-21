xml.instruct!

xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title t("api.notes.rss.title")
    xml.description t("api.notes.rss.description_item", :id => @note.id)
    xml.link url_for(:controller => "/site", :action => "index", :only_path => false)

    xml << render(@note)
  end
end
