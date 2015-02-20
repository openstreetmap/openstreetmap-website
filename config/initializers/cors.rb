require "rack/cors"

# Mark CORS responses as uncacheable as we don't want a browser to
# try and reuse a response that had a different origin, even with
# revalidation, as the origin check will fail.
module OpenStreetMap
  class Cors < Rack::Cors
    def call(env)
      status, headers, body = super env
      if headers["Access-Control-Allow-Origin"]
        headers["Cache-Control"] = "no-cache"
      end
      [status, headers, body]
    end
  end
end

# Allow any and all cross-origin requests to the API. Allow any origin, and
# any headers. Non-browser requests do not have origin or header restrictions,
# so browser-requests should be similarly permitted. (Though the API does not
# require any custom headers, Ajax frameworks may automatically add headers
# such as X-Requested-By to requests.)
Rails.configuration.middleware.use OpenStreetMap::Cors do
  allow do
    origins "*"
    resource "/oauth/*", :headers => :any, :methods => [:get, :post]
    resource "/api/*", :headers => :any, :methods => [:get, :post, :put, :delete]
  end
end
