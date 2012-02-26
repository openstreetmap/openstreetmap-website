module Paperclip
  class AssetUrlGenerator < UrlGenerator
    include Sprockets::Helpers::IsolatedHelper
    include Sprockets::Helpers::RailsHelper

    def for(style_name, options)
      url = super(style_name, options)

      if url =~ /^\/assets\/(.*)$/
        asset_path($1)
      else
        url
      end
    end
  end
end

Paperclip::Attachment.default_options[:url] = "/attachments/:class/:attachment/:id_partition/:style/:fingerprint.:extension"
Paperclip::Attachment.default_options[:path] = "#{ATTACHMENTS_DIR}/:class/:attachment/:id_partition/:style/:fingerprint.:extension"
Paperclip::Attachment.default_options[:url_generator] = Paperclip::AssetUrlGenerator
