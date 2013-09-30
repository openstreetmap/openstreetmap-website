module Paperclip
  class AssetUrlGenerator < UrlGenerator
    include Sprockets::Rails::Helper

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

Rails.application.config.after_initialize do |app|
  Paperclip::AssetUrlGenerator::VIEW_ACCESSORS.each do |attr|
    Paperclip::AssetUrlGenerator.send("#{attr}=", ActionView::Base.send(attr))
  end
end

Paperclip::Attachment.default_options[:url] = "/attachments/:class/:attachment/:id_partition/:style/:fingerprint.:extension"
Paperclip::Attachment.default_options[:path] = "#{ATTACHMENTS_DIR}/:class/:attachment/:id_partition/:style/:fingerprint.:extension"
Paperclip::Attachment.default_options[:url_generator] = Paperclip::AssetUrlGenerator
