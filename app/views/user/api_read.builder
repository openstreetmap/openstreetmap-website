xml.instruct! :xml, :version => "1.0"
xml.osm("version" => API_VERSION, "generator" => GENERATOR) do
  xml.tag! "user", :id => @this_user.id,
                   :display_name => @this_user.display_name,
                   :account_created => @this_user.creation_time.xmlschema do
    if @this_user.description
      xml.tag! "description", @this_user.description
    end
    if @user && @user == @this_user
      xml.tag! "contributor-terms", :agreed => @this_user.terms_agreed.present?,
                                    :pd => @this_user.consider_pd
    else
      xml.tag! "contributor-terms", :agreed => @this_user.terms_agreed.present?
    end
    if @this_user.image.file? or @this_user.image_use_gravatar
      xml.tag! "img", :href => user_image_url(@this_user, :size => 256)
    end
    xml.tag! "roles" do
      @this_user.roles.each do |role|
        xml.tag! role.role
      end
    end
    xml.tag! "changesets", :count => @this_user.changesets.size
    xml.tag! "traces", :count => @this_user.traces.size
    xml.tag! "blocks" do
      xml.tag! "received", :count => @this_user.blocks.size,
                           :active => @this_user.blocks.active.size
      if @this_user.moderator?
        xml.tag! "issued", :count => @this_user.blocks_created.size,
                           :active => @this_user.blocks_created.active.size
      end
    end
    if @user && @user == @this_user
      if @this_user.home_lat and @this_user.home_lon
        xml.tag! "home", :lat => @this_user.home_lat,
                         :lon => @this_user.home_lon,
                         :zoom => @this_user.home_zoom
      end
      if @this_user.languages
        xml.tag! "languages" do
          @this_user.languages.split(",") { |lang| xml.tag! "lang", lang }
        end
      end
      xml.tag! "messages" do
        xml.tag! "received", :count => @this_user.messages.size,
                             :unread => @this_user.new_messages.size
        xml.tag! "sent", :count => @this_user.sent_messages.size
      end
    end
  end
end
