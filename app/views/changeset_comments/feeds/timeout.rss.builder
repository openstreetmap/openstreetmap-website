xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    if params[:changeset_id]
      xml.title t("changeset_comments.feeds.show.title_particular", :changeset_id => params[:changeset_id])
    else
      xml.title t("changeset_comments.feeds.show.title_all")
    end
    xml.link root_url
    xml.description t(".sorry")
  end
end
