# Be sure to restart your server when you modify this file.

if STATUS == :database_offline or STATUS == :database_readonly
  OpenStreetMap::Application.config.session_store :cookie_store, :key => '_osm_session'
else
  ActiveRecord::SessionStore.session_class = ActiveRecord::SessionStore::SqlBypass
  OpenStreetMap::Application.config.session_store :active_record_store, :key => '_osm_session'
end
