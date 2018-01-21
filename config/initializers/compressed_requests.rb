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
        extracted = decode(env["rack.input"], env["HTTP_CONTENT_ENCODING"])

        env.delete("HTTP_CONTENT_ENCODING")
        env["CONTENT_LENGTH"] = extracted.bytesize
        env["rack.input"] = StringIO.new(extracted)
      end

      if env["HTTP_CONTENT_ENCODING"]
        [415, {}, []]
      else
        @app.call(env)
      end
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
