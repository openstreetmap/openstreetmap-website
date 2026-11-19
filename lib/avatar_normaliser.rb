# frozen_string_literal: true

# Re-encodes uploaded avatars, to avoid storing the original file.
# The result has limited dimensions (and therefore filesize),
# has only the first frame of any animation,
# and has all metadata (such as EXIF location) stripped.
module AvatarNormaliser
  # Maximum width and height of a normalised avatar
  MAX_DIMENSION = 512

  # Returns an attachable hash for the normalised image. Raises Vips::Error
  # if the image can't be processed.
  def self.normalise(io, content_type)
    io.rewind
    image = Vips::Image.new_from_buffer(io.read, "").autorot
    image = image.icc_transform("srgb", :embedded => true) if image.get_typeof("icc-profile-data").nonzero?

    format = if ActiveStorage.web_image_content_types.include?(content_type)
               Marcel::Magic.new(content_type).extensions.first
             else
               "png"
             end

    file = ImageProcessing::Vips.source(image)
                                .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
                                .saver(:strip => true)
                                .convert(format)
                                .call

    { :io => file, :filename => "avatar.#{format}" }
  end
end
