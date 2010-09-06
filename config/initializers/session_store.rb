# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_osm_session',
  :secret      => 'd886369b1e709c61d1f9fcb07384a2b96373c83c01bfc98c6611a9fe2b6d0b14215bb360a0154265cccadde5489513f2f9b8d9e7b384a11924f772d2872c2a1f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
unless STATUS == :database_offline or STATUS == :database_readonly
  ActionController::Base.session_store = :sql_session_store
end
