require "rack/cors"

# Allow any and all cross-origin requests to the API. Allow any origin, and
# any headers. Non-browser requests do not have origin or header restrictions,
# so browser-requests should be similarly permitted. (Though the API does not
# require any custom headers, Ajax frameworks may automatically add headers
# such as X-Requested-By to requests.)
Rails.configuration.middleware.use Rack::Cors do
  allow do
    origins "*"
    resource "/oauth/*", :headers => :any, :methods => [:get, :post]
    resource "/api/*", :headers => :any, :methods => [:get, :post, :put, :delete]
  end
end
