# frozen_string_literal: true

module OpenStreetMap
  class CompressedRequests
    def initialize(app)
      @app = app
    end

    def method_handled?(method)
      %w[POST PUT].include? method
    end

    def encoding_handled?(encoding)
      %w[gzip deflate].include? encoding
    end

    def call(env)
      encoding = env.delete("HTTP_CONTENT_ENCODING")

      if method_handled?(env["REQUEST_METHOD"]) && encoding_handled?(encoding)
        begin
          extracted = decode(env[::Rack::RACK_INPUT], encoding)

          env.delete(::Rack::RACK_REQUEST_FORM_ERROR)
          env.delete(::Rack::RACK_REQUEST_FORM_HASH)
          env.delete(::Rack::RACK_REQUEST_FORM_INPUT)
          env.delete(::Rack::RACK_REQUEST_FORM_PAIRS)
          env["CONTENT_LENGTH"] = extracted.bytesize
          env[::Rack::RACK_INPUT] = StringIO.new(extracted)
        rescue Zlib::Error
          response = [422, {}, []]
        end
      elsif encoding
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
