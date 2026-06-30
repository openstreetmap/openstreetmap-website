# frozen_string_literal: true

# Active Storage loads S3Service lazily, so we require it before subclassing.
# Without this, eager loading fails with an uninitialized constant.
require "active_storage/service/s3_service"

# Plain GPX traces are stored gzipped, so they need Content-Encoding: gzip on S3.
# That way the client unzips the file, not the server. This service only adds that
# header on upload and inherits the rest from the parent S3 service.

module ActiveStorage
  class Service::GpxS3Service < Service::S3Service
    # True so the download can redirect to S3 instead of unzipping on the server.
    def serves_content_encoding?
      true
    end

    private

    def upload_with_single_part(key, io, checksum: nil, content_type: nil, content_disposition: nil, custom_metadata: {})
      # The model marks server-gzipped files with custom_metadata, because Active
      # Storage's upload has no Content-Encoding argument. We keep the flag in the
      # blob metadata for the download, but we don't write it to the S3 object as
      # x-amz-meta.
      return super unless custom_metadata["server_gzipped"]

      object_for(key).put(:body => io,
                          :content_md5 => checksum,
                          :content_type => content_type,
                          :content_encoding => "gzip",
                          :content_disposition => content_disposition,
                          :metadata => custom_metadata.except("server_gzipped"),
                          **upload_options)
    rescue Aws::S3::Errors::BadDigest
      raise ActiveStorage::IntegrityError
    end

    def upload_with_multipart(key, io, content_type: nil, content_disposition: nil, custom_metadata: {})
      return super unless custom_metadata["server_gzipped"]

      part_size = [io.size.fdiv(MAXIMUM_UPLOAD_PARTS_COUNT).ceil, MINIMUM_UPLOAD_PART_SIZE].max

      upload_stream(:key => key,
                    :content_type => content_type,
                    :content_encoding => "gzip",
                    :content_disposition => content_disposition,
                    :part_size => part_size,
                    :metadata => custom_metadata.except("server_gzipped"),
                    **upload_options) do |out|
        IO.copy_stream(io, out)
      end
    end
  end
end
