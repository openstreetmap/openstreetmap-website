xml.tag! "user", :id => api_user.id,
                 :display_name => api_user.display_name,
                 :account_created => api_user.creation_time.xmlschema do
  xml.tag! "description", api_user.description if api_user.description
  if current_user && current_user == api_user
    xml.tag! "contributor-terms", :agreed => api_user.terms_agreed.present?,
                                  :pd => api_user.consider_pd
  else
    xml.tag! "contributor-terms", :agreed => api_user.terms_agreed.present?
  end
  xml.tag! "img", :href => user_image_url(api_user) if api_user.image.file? || api_user.image_use_gravatar
  xml.tag! "roles" do
    api_user.roles.each do |role|
      xml.tag! role.role
    end
  end
  xml.tag! "changesets", :count => api_user.changesets.size
  xml.tag! "traces", :count => api_user.traces.size
  xml.tag! "blocks" do
    xml.tag! "received", :count => api_user.blocks.size,
                         :active => api_user.blocks.active.size
    if api_user.moderator?
      xml.tag! "issued", :count => api_user.blocks_created.size,
                         :active => api_user.blocks_created.active.size
    end
  end
  if current_user && current_user == api_user
    if api_user.home_lat && api_user.home_lon
      xml.tag! "home", :lat => api_user.home_lat,
                       :lon => api_user.home_lon,
                       :zoom => api_user.home_zoom
    end
    if api_user.languages
      xml.tag! "languages" do
        api_user.languages.split(",") { |lang| xml.tag! "lang", lang }
      end
    end
    xml.tag! "messages" do
      xml.tag! "received", :count => api_user.messages.size,
                           :unread => api_user.new_messages.size
      xml.tag! "sent", :count => api_user.sent_messages.size
    end
  end
end
