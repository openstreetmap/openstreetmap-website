# Stop rails from automatically parsing XML in request bodies
Rails.configuration.middleware.delete ActionDispatch::ParamsParser
