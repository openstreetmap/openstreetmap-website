# frozen_string_literal: true

xml.tag! "user", :id => user.id,
                 :display_name => user.display_name,
                 :account_created => user.created_at.xmlschema do
  xml.tag! "description", user.description if user.description
  xml.tag! "company", user.company if user.company

  xml.tag! "social-links" do
    user.social_links.each do |link|
      details = link.parsed
      xml.tag! "link", details[:url], :platform => details[:platform]
    end
  end

  if current_user && current_user == user && can?(:details, User)
    xml.tag! "contributor-terms", :agreed => user.terms_agreed.present?,
                                  :pd => user.consider_pd
  else
    xml.tag! "contributor-terms", :agreed => user.terms_agreed.present?
  end
  xml.tag! "img", :href => user_image_url(user) if user.avatar.attached? || user.image_use_gravatar
  xml.tag! "roles" do
    user.roles.each do |role|
      xml.tag! role.role
    end
  end
  xml.tag! "changesets", :count => user.changesets.size
  xml.tag! "traces", :count => user.traces.size
  xml.tag! "blocks" do
    xml.tag! "received", :count => user.blocks.size,
                         :active => user.blocks.active.size
    if user.moderator?
      xml.tag! "issued", :count => user.blocks_created.size,
                         :active => user.blocks_created.active.size
    end
  end
  if current_user && current_user == user && can?(:details, User)
    if user.home_location?
      xml.tag! "home", :lat => user.home_lat,
                       :lon => user.home_lon,
                       :zoom => user.home_zoom
    end
    if user.languages
      xml.tag! "languages" do
        user.languages.split(",") { |lang| xml.tag! "lang", lang }
      end
    end
    xml.tag! "messages" do
      xml.tag! "received", :count => user.messages.size,
                           :unread => user.new_messages.size
      xml.tag! "sent", :count => user.sent_messages.size
    end
    xml.tag! "email", user.email if scope_enabled?(:read_email)
  end
end
