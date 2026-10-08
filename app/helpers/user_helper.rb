# frozen_string_literal: true

module UserHelper
  # User images

  USER_IMAGE_SIZES = { :user_thumbnail_tiny => 25, :user_thumbnail => 50, :user_image => 100 }.freeze

  def user_image(user, options = {})
    user_image_tag(user, :user_image, options)
  end

  def user_thumbnail(user, options = {})
    user_image_tag(user, :user_thumbnail, options)
  end

  def user_thumbnail_tiny(user, options = {})
    user_image_tag(user, :user_thumbnail_tiny, options)
  end

  def user_image_url(user)
    if user.image_use_gravatar
      user_gravatar_url(user)
    elsif user.avatar.attached?
      polymorphic_url(user_avatar_variant(user, :resize_to_limit => [100, 100]), :host => Settings.server_url)
    else
      image_url("avatar.svg")
    end
  end

  private

  def user_image_tag(user, size, options = {})
    options = { :class => "border border-secondary-subtle bg-body", :alt => "" }.merge(options)
    options[:class] = "#{size} " + options[:class]

    size = USER_IMAGE_SIZES[size]

    if user.image_use_gravatar
      user_gravatar_tag(user, options.merge(:size => size))
    elsif user.avatar.attached?
      user_avatar_variant_tag(user, { :resize_to_limit => [size, size] }, options)
    else
      image_tag "avatar.svg", options.merge(:width => size, :height => size)
    end
  end

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
    options[:height] = options[:width] = options.delete(:size)
    image_tag url, options
  end
end
