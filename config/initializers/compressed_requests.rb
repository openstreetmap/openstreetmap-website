# frozen_string_literal: true

module OpenStreetMap
  class CompressedRequests
    def initialize(app)
      @app = app
    end

    def method_handled?(env)
      %w[POST PUT].include? env["REQUEST_METHOD"]
    end

    def encoding_handled?(env)
      %w[gzip deflate].include? env["HTTP_CONTENT_ENCODING"]
    end

    def call(env)
      if method_handled?(env) && encoding_handled?(env)
        begin
          extracted = decode(env[::Rack::RACK_INPUT], env["HTTP_CONTENT_ENCODING"])

          env.delete("HTTP_CONTENT_ENCODING")
          env.delete(::Rack::RACK_REQUEST_FORM_ERROR)
          env.delete(::Rack::RACK_REQUEST_FORM_HASH)
          env.delete(::Rack::RACK_REQUEST_FORM_INPUT)
          env.delete(::Rack::RACK_REQUEST_FORM_PAIRS)
          env["CONTENT_LENGTH"] = extracted.bytesize
          env[::Rack::RACK_INPUT] = StringIO.new(extracted)
        rescue Zlib::GzipFile::Error, Zlib::DataError
          response = [422, {}, []]
        end
      elsif env["HTTP_CONTENT_ENCODING"]
        response = [415, {}, []]
      end

      response || @app.call(env)
    end

    def decode(input, content_encoding)
      input.rewind

      case content_encoding
      when "gzip" then Zlib::GzipReader.new(input).read
      when "deflate" then Zlib::Inflate.inflate(input.read)
      end
    end
  end
end

Rails.configuration.middleware.use OpenStreetMap::CompressedRequests
