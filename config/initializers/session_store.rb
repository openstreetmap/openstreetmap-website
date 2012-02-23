# Be sure to restart your server when you modify this file.

if defined?(MEMCACHE_SERVERS)
  unless STATUS == :database_offline or STATUS == :database_readonly
    module Rack
      module Session
        class Memcache
          def get_session(env, sid)
            with_lock(env, [nil, {}]) do
              unless sid and session = @pool.get(sid)
                if sid and s = ActiveRecord::SessionStore::SqlBypass.find_by_session_id(sid)
                  session = s.data
                  s.destroy
                else
                  sid, session = generate_sid, {}
                end
                
                unless /^STORED/ =~ @pool.add(sid, session)
                  raise "Session collision on '#{sid.inspect}'"
                end
              end
              [sid, session]
            end
          end
        end
      end
    end
  end

  cache = MemCache.new(:namespace => "rails:session", :string_return_types => true)

  OpenStreetMap::Application.config.session_store :mem_cache_store, :cache => cache, :key => "_osm_session"
else
  OpenStreetMap::Application.config.session_store :cookie_store, :key => '_osm_session'
end
