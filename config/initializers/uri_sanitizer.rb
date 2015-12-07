# Add URI sanitizer to rack middleware
Rails.configuration.middleware.insert_before Rack::Runtime, Rack::URISanitizer
