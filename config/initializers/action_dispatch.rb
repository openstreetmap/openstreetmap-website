# Stop rails from automatically parsing XML in request bodies
Rails.configuration.middleware.delete ActionDispatch::ParamsParser

# https://github.com/rails/rails/issues/20710
module ActionDispatch
  module Assertions
    def html_document_with_rss
      @html_document ||= if @response.content_type == Mime::RSS
                           Nokogiri::XML::Document.parse(@response.body)
                         else
                           html_document_without_rss
                         end
    end

    alias_method_chain :html_document, :rss
  end
end
