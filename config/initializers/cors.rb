# Be sure to restart your server when you modify this file.

# Mark CORS responses as uncacheable as we don't want a browser to
# try and reuse a response that had a different origin, even with
# revalidation, as the origin check will fail.
module OpenStreetMap
  class Cors < Rack::Cors
    def call(env)
      status, headers, body = super env
      headers["Cache-Control"] = "no-cache" if headers["Access-Control-Allow-Origin"]
      [status, headers, body]
    end
  end
end

# Allow any and all cross-origin requests to the API. Allow any origin, and
# any headers. Non-browser requests do not have origin or header restrictions,
# so browser-requests should be similarly permitted. (Though the API does not
# require any custom headers, Ajax frameworks may automatically add headers
# such as X-Requested-By to requests.)
Rails.application.config.middleware.insert_before 0, OpenStreetMap::Cors do
  allow do
    origins "*"
    resource "/oauth/*", :headers => :any, :methods => [:get, :post]
    resource "/api/*", :headers => :any, :methods => [:get, :post, :put, :delete]
    resource "/diary/rss", :headers => :any, :methods => [:get]
    resource "/diary/*/rss", :headers => :any, :methods => [:get]
    resource "/user/*/diary/rss", :headers => :any, :methods => [:get]
  end
end
