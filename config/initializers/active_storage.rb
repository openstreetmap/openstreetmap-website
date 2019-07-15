Rails.configuration.after_initialize do
  require "active_storage/service/s3_service"
  require_dependency "active_storage/variant"

  module OpenStreetMap
    module ActiveStorage
      module Variant
        private

        def upload(image)
          File.open(image.path, "r") { |file| service.upload(key, file, :content_type => content_type) }
        end
      end

      module S3Service
        def upload(key, io, content_type:, **options)
          @upload_options[:content_type] = content_type
          super(key, io, **options)
          @upload_options.delete(:content_type)
        end
      end
    end
  end

  ActiveStorage::Variant.prepend(OpenStreetMap::ActiveStorage::Variant)
  ActiveStorage::Service::S3Service.prepend(OpenStreetMap::ActiveStorage::S3Service)

  ActiveSupport::Reloader.to_complete do
    ActiveStorage::Variant.prepend(OpenStreetMap::ActiveStorage::Variant)
  end
end
