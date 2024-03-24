feed_params = params.permit(:format, :display_name, :bbox, :friends, :nearby)

atom_feed(:language => I18n.locale, :schema_date => 2009,
          :id => url_for(feed_params.merge(:only_path => false)),
          :root_url => url_for(feed_params.merge(:action => :index, :format => nil, :only_path => false)),
          "xmlns:georss" => "http://www.georss.org/georss") do |feed|
  feed.title @title

  feed.subtitle :type => "xhtml" do |xhtml|
    xhtml.p do |p|
      p << t(".sorry")
    end
  end
end
