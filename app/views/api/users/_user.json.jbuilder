json.user do
  json.id user.id
  json.display_name user.display_name
  json.account_created user.created_at.xmlschema
  json.description user.description if user.description

  if current_user && current_user == user && can?(:details, User)
    json.contributor_terms do
      json.agreed user.terms_agreed.present?
      json.pd user.consider_pd
    end
  else
    json.contributor_terms do
      json.agreed user.terms_agreed.present?
    end
  end

  json.img do
    json.href user_image_url(user) if user.avatar.attached? || user.image_use_gravatar
  end

  json.roles do
    json.array! user.roles.map(&:role)
  end

  json.changesets do
    json.count user.changesets.size
  end

  json.traces do
    json.count user.traces.size
  end

  json.blocks do
    json.received do
      json.count user.blocks.size
      json.active user.blocks.active.size
    end

    if user.moderator?
      json.issued do
        json.count user.blocks_created.size
        json.active user.blocks_created.active.size
      end
    end
  end

  if current_user && current_user == user && can?(:details, User)
    if user.home_lat && user.home_lon
      json.home do
        json.lat user.home_lat
        json.lon user.home_lon
        json.zoom user.home_zoom
      end
    end

    json.languages user.languages if user.languages?

    json.messages do
      json.received do
        json.count user.messages.size
        json.unread user.new_messages.size
      end
      json.sent do
        json.count user.sent_messages.size
      end
    end

    json.email user.email if scope_enabled?(:read_email)
  end
end
