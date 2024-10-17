# Be sure to restart your server when you modify this file.

# frozen_string_literal: true

# By default, all sessions are given the same expiration time configured in
# the session store (e.g. 30 days). However, unauthenticated users can
# generate a lot of sessions, primarily for CSRF verification.
# It makes sense to reduce the TTL for unauthenticated to something
# much lower than the default (e.g. a few hours) to limit Memcached memory.
# In addition, Rails creates a new session after login, so the short TTL
# doesn't even need to be extended.

module OpenStreetMap
  class UnauthenticatedSessionExpiry
    def initialize(app)
      @app = app
    end

    def call(env)
      result = @app.call(env)

      # TODO: is this the correct way to check for a logged on user?
      session = env["rack.session"]
      user = session["user"]

      unless user
        # This works because Rack uses these options every time a request is handled, and dalli uses the Rack setting first:
        # 1. https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L342
        # 2. https://github.com/petergoldstein/dalli/blob/main/lib/rack/session/dalli.rb
        #
        expire_after = Settings["unauthenticated_session_expire_delay"] ||= 0

        env["rack.session.options"][:expire_after] = expire_after if expire_after != 0
      end

      result
    end
  end
end

if Settings.key?(:memcache_servers)
  Rails.application.configure do
    config.session_store :mem_cache_store, :memcache_server => Settings.memcache_servers, :namespace => "rails:session", :key => "_osm_session", :same_site => :lax

    config.middleware.insert_after ActionDispatch::Session::MemCacheStore, OpenStreetMap::UnauthenticatedSessionExpiry
  end

else
  Rails.application.config.session_store :cache_store, :key => "_osm_session", :cache => ActiveSupport::Cache::MemoryStore.new, :same_site => :lax
end
