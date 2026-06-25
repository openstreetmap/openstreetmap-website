# frozen_string_literal: true

# S3Service is loaded lazily by Active Storage, so require it before subclassing
# or eager loading fails with an uninitialized constant.
require "active_storage/service/s3_service"

# Plain GPX traces are stored gzipped, so they need Content-Encoding: gzip on S3
# to let the client unzip them instead of the server. This service extends Active
# Storage's S3 service to add that header on upload.

module ActiveStorage
  class Service::GpxS3Service < Service::S3Service
    def upload(key, io, custom_metadata: {}, **options)
      # Active Storage's upload has no Content-Encoding argument, so the model
      # flags server-gzipped files through custom_metadata. Read the flag without
      # removing it, so the blob keeps it for the download, and set the real
      # Content-Encoding header. The blob metadata keeps the flag, the S3 object
      # doesn't get it as x-amz-meta. That difference is intentional.
      return super unless custom_metadata["server_gzipped"]

      checksum = options[:checksum]
      filename = options[:filename]
      disposition = options[:disposition]

      instrument :upload, :key => key, :checksum => checksum do
        content_disposition = content_disposition_with(:filename => filename, :type => disposition) if disposition && filename

        object_for(key).put(:body => io,
                            :content_md5 => checksum,
                            :content_type => options[:content_type],
                            :content_encoding => "gzip",
                            :content_disposition => content_disposition,
                            :metadata => custom_metadata.except("server_gzipped"),
                            **upload_options)
      rescue Aws::S3::Errors::BadDigest
        raise ActiveStorage::IntegrityError
      end
    end

    # True so the download can redirect to S3 instead of unzipping on the server.
    def serves_content_encoding?
      true
    end
  end
end
