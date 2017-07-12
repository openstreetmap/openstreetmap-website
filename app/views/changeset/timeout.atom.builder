atom_feed(:language => I18n.locale, :schema_date => 2009,
          :id => url_for(params.merge(:only_path => false)),
          :root_url => url_for(params.merge(:only_path => false, :format => nil)),
          "xmlns:georss" => "http://www.georss.org/georss") do |feed|
  feed.title @title

  feed.subtitle :type => "xhtml" do |xhtml|
    xhtml.p do |p|
      p << t("changeset.timeout.sorry")
    end
  end
end
