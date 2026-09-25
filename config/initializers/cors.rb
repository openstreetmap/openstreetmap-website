# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Allow any and all cross-origin requests to the API. Allow any origin, and
# any headers. Non-browser requests do not have origin or header restrictions,
# so browser-requests should be similarly permitted. (Though the API does not
# require any custom headers, Ajax frameworks may automatically add headers
# such as X-Requested-By to requests.)
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/oauth/*", :headers => :any, :methods => [:get, :post]
    resource "/oauth2/token", :headers => :any, :methods => [:post]
    resource "/oauth2/revoke", :headers => :any, :methods => [:post]
    resource "/oauth2/introspect", :headers => :any, :methods => [:post]
    resource "/api/*", :headers => :any, :methods => [:get, :post, :put, :delete]
    resource "/diary/rss", :headers => :any, :methods => [:get]
    resource "/diary/*/rss", :headers => :any, :methods => [:get]
    resource "/trace/*/data", :headers => :any, :methods => [:get]
    resource "/user/*/diary/rss", :headers => :any, :methods => [:get]
    resource "/rails/active_storage/*", :headers => :any, :methods => [:get]
  end
end
