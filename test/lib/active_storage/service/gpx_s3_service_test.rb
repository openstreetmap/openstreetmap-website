# frozen_string_literal: true

require "test_helper"

class GpxS3ServiceTest < ActiveSupport::TestCase
  class MultipartTest < self
    def setup
      @service = ActiveStorage::Service::GpxS3Service.new(
        :bucket => "test-bucket",
        :region => "eu-west-1",
        :stub_responses => true,
        :upload => {
          :multipart_threshold => 1.byte
        }
      )
    end

    private

    def find_latest_upload_request
      @service.client.client.api_requests.reverse_each.find { |request| request[:operation_name] == :create_multipart_upload }
    end
  end

  def setup
    @service = ActiveStorage::Service::GpxS3Service.new(
      :bucket => "test-bucket",
      :region => "eu-west-1",
      :stub_responses => true
    )
  end

  def test_sets_content_encoding_for_server_gzipped_flag
    @service.upload("key", StringIO.new("data"),
                    :content_type => "application/gpx+xml",
                    :custom_metadata => { "server_gzipped" => true })

    request = find_latest_upload_request
    assert_equal "gzip", request[:params][:content_encoding]
    # The flags drive the header, they aren't stored as S3 metadata.
    assert_empty(request[:params][:metadata] || {})
  end

  def test_keeps_default_upload_without_server_gzipped_flag
    @service.upload("key", StringIO.new("data"), :content_type => "application/gpx+xml")

    assert_nil find_latest_upload_request[:params][:content_encoding]
  end

  def test_keeps_metadata_flag
    custom_metadata = { "server_gzipped" => true }
    @service.upload("key", StringIO.new("data"),
                    :content_type => "application/gpx+xml",
                    :custom_metadata => custom_metadata)

    # The blob keeps the flag for the download, so the upload must not remove it.
    assert custom_metadata["server_gzipped"]
  end

  def test_adds_gzip_content_encoding_flag
    custom_metadata = { "server_gzipped" => true }
    @service.upload("key", StringIO.new("data"),
                    :content_type => "application/gpx+xml",
                    :custom_metadata => custom_metadata)

    # The service sets the Content-Encoding header on the upload, so it records
    # the flag on the blob. The download reads it to decide if it can redirect.
    assert custom_metadata["gzip_content_encoding"]
  end

  private

  def find_latest_upload_request
    @service.client.client.api_requests.reverse_each.find { |request| request[:operation_name] == :put_object }
  end
end
