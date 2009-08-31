xml.instruct! :xml, :version => "1.0"
xml.osm("version" => API_VERSION, "generator" => GENERATOR) do
  xml.tag! "user", :id => @user.id,
                   :display_name => @user.display_name,
                   :account_created => @user.creation_time.xmlschema do
    if @user.description
      xml.tag! "description", @user.description
    end
    if @user.home_lat and @user.home_lon
      xml.tag! "home", :lat => @user.home_lat,
                       :lon => @user.home_lon,
                       :zoom => @user.home_zoom
    end    
    if @user.image
      # i'd love to use "url_for_file_column, :absolute=>true", but that doesn't seem
      # to work with the file_column plugin version we're using.
      xml.tag! "img", :href => ("http://" + SERVER_URL + url_for_file_column(@user, "image"))
    end
    if @user.languages
      xml.tag! "languages" do
        @user.languages.split(",") { |lang| xml.tag! "lang", lang }
      end
    end
  end
end
