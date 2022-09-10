module UserHelper
  # User images

  def user_image(user, options = {})
    options[:class] ||= "user_image border border-grey"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options)
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [100, 100] }, options)
    else
      image_tag "avatar_large.png", options.merge(:width => 100, :height => 100)
    end
  end

  def user_thumbnail(user, options = {})
    options[:class] ||= "user_thumbnail border border-grey"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options.merge(:size => 50))
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [50, 50] }, options)
    else
      image_tag "avatar_small.png", options.merge(:width => 50, :height => 50)
    end
  end

  def user_thumbnail_tiny(user, options = {})
    options[:class] ||= "user_thumbnail_tiny border border-grey"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options.merge(:size => 50))
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [50, 50] }, options)
    else
      image_tag "avatar_small.png", options.merge(:width => 50, :height => 50)
    end
  end

  def user_image_url(user, options = {})
    if user.image_use_gravatar
      user_gravatar_url(user, options)
    elsif user.avatar.attached?
      polymorphic_url(user_avatar_variant(user, :resize_to_limit => [100, 100]), :host => Settings.server_url)
    else
      image_url("avatar_large.png")
    end
  end

  # External authentication support

  def openid_logo
    image_tag "openid_small.png", :alt => t("sessions.new.openid_logo_alt"), :class => "openid_logo"
  end

  def auth_button(name, provider, options = {})
    link_to(
      image_tag("#{name}.svg", :alt => t("sessions.new.auth_providers.#{name}.alt"), :class => "rounded-3"),
      auth_path(options.merge(:provider => provider)),
      :method => :post,
      :class => "auth_button",
      :title => t("sessions.new.auth_providers.#{name}.title")
    )
  end

  private

  # Local avatar support
  def user_avatar_variant_tag(user, variant_options, options)
    if user.avatar.variable?
      variant = user.avatar.variant(variant_options)
      # https://stackoverflow.com/questions/61893089/get-metadata-of-active-storage-variant/67228171
      if variant.processed?
        metadata = variant.processed.send(:record).image.blob.metadata
        if metadata["width"]
          options[:width] = metadata["width"]
          options[:height] = metadata["height"]
        end
      end
      image_tag variant, options
    else
      image_tag user.avatar, options
    end
  end

  def user_avatar_variant(user, options)
    if user.avatar.variable?
      user.avatar.variant(options)
    else
      user.avatar
    end
  end

  # Gravatar support

  # See http://en.gravatar.com/site/implement/images/ for details.
  def user_gravatar_url(user, options = {})
    size = options[:size] || 100
    hash = Digest::MD5.hexdigest(user.email.downcase)
    default_image_url = image_url("avatar_large.png")
    "#{request.protocol}www.gravatar.com/avatar/#{hash}.jpg?s=#{size}&d=#{u(default_image_url)}"
  end

  def user_gravatar_tag(user, options = {})
    url = user_gravatar_url(user, options)
    options[:height] = options[:width] = options.delete(:size) || 100
    image_tag url, options
  end
end
