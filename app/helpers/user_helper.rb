module UserHelper
  # User images

  def user_image(user, options = {})
    options[:class] ||= "user_image border border-secondary-subtle bg-body"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options)
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [100, 100] }, options)
    else
      image_tag "avatar.svg", options.merge(:width => 100, :height => 100)
    end
  end

  def user_thumbnail(user, options = {})
    options[:class] ||= "user_thumbnail border border-secondary-subtle bg-body"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options.merge(:size => 50))
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [50, 50] }, options)
    else
      image_tag "avatar.svg", options.merge(:width => 50, :height => 50)
    end
  end

  def user_thumbnail_tiny(user, options = {})
    options[:class] ||= "user_thumbnail_tiny border border-secondary-subtle bg-body"
    options[:alt] ||= ""

    if user.image_use_gravatar
      user_gravatar_tag(user, options.merge(:size => 50))
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [50, 50] }, options)
    else
      image_tag "avatar.svg", options.merge(:width => 50, :height => 50)
    end
  end

  def user_image_url(user, options = {})
    if user.image_use_gravatar
      user_gravatar_url(user, options)
    elsif user.avatar.attached?
      polymorphic_url(user_avatar_variant(user, :resize_to_limit => [100, 100]), :host => Settings.server_url)
    else
      image_url("avatar.svg")
    end
  end

  # External authentication support

  def auth_button(provider, options = {})
    link_to(
      image_tag("auth_providers/#{provider}.svg",
                :alt => t("application.auth_providers.#{provider}.alt"),
                :class => "rounded-1",
                :size => "36"),
      auth_path(options.merge(:provider => provider)),
      :method => :post,
      :class => "auth_button btn btn-outline-secondary border p-2",
      :title => t("application.auth_providers.#{provider}.title")
    )
  end

  def auth_button_preferred(provider, options = {})
    link_to(
      image_tag("auth_providers/#{provider}.svg",
                :alt => t("application.auth_providers.#{provider}.alt"),
                :class => "rounded-1 me-3",
                :size => "36") + t("application.auth_providers.#{provider}.title"),
      auth_path(options.merge(:provider => provider)),
      :method => :post,
      :class => "auth_button btn btn-outline-secondary border py-2 px-4 d-flex justify-content-center align-items-center",
      :title => t("application.auth_providers.#{provider}.title")
    )
  end

  private

  # Local avatar support
  def user_avatar_variant_tag(user, variant_options, options)
    if user.avatar.variable?
      variant = user.avatar.variant(variant_options)
      # https://stackoverflow.com/questions/61893089/get-metadata-of-active-storage-variant/67228171
      if variant.send(:processed?)
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
