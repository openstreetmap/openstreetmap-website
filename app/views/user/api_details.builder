xml.instruct! :xml, :version => "1.0"
xml.osm("version" => API_VERSION, "generator" => GENERATOR) do
  xml.tag! "user", :id => @user.id,
                   :display_name => @user.display_name,
                   :account_created => @user.creation_time.xmlschema do
    if @user.description
      xml.tag! "description", @user.description
    end
    xml.tag! "contributor-terms",
        :agreed => !!@user.terms_agreed,
        :pd => !!@user.consider_pd
    if @user.home_lat and @user.home_lon
      xml.tag! "home", :lat => @user.home_lat,
                       :lon => @user.home_lon,
                       :zoom => @user.home_zoom
    end    
    if @user.image
      xml.tag! "img", :href => (url_for_file_column(@user, "image", :absolute => true))
    end
    if @user.languages
      xml.tag! "languages" do
        @user.languages.split(",") { |lang| xml.tag! "lang", lang }
      end
    end
  end
end
