# Work out which session store adapter to use
adapter = Rails.configuration.database_configuration[Rails.env]["adapter"]
session_class = adapter + "_session"

# Configure SqlSessionStore
unless STATUS == :database_offline
  SqlSessionStore.session_class = session_class.camelize.constantize
end
