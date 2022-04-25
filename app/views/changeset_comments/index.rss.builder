xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    if @changeset
      xml.title t(".title_particular", :changeset_id => @changeset.id)
    else
      xml.title t(".title_all")
    end
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)

    xml << render(:partial => "comments", :object => @comments)
  end
end
