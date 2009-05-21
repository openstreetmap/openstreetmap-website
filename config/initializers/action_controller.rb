# Stop action controller from automatically parsing XML in request bodies
ActionController::Base.param_parsers.delete Mime::XML

