xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    if params[:id]
      xml.title t("changeset_comments.index.title_particular", :changeset_id => params[:id])
    else
      xml.title t("changeset_comments.index.title_all")
    end
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)
    xml.description t(".sorry")
  end
end
