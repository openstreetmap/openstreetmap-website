ActionController::Routing::Routes.draw do |map|
  # API
  map.connect "api/capabilities", :controller => 'api', :action => 'capabilities'
  map.connect "api/#{API_VERSION}/capabilities", :controller => 'api', :action => 'capabilities'

  map.connect "api/#{API_VERSION}/changeset/create", :controller => 'changeset', :action => 'create'
  map.connect "api/#{API_VERSION}/changeset/:id/upload", :controller => 'changeset', :action => 'upload', :id => /\d+/
  map.changeset_download "api/#{API_VERSION}/changeset/:id/download", :controller => 'changeset', :action => 'download', :id => /\d+/
  map.connect "api/#{API_VERSION}/changeset/:id/expand_bbox", :controller => 'changeset', :action => 'expand_bbox', :id => /\d+/
  map.changeset_read "api/#{API_VERSION}/changeset/:id", :controller => 'changeset', :action => 'read', :id => /\d+/, :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/changeset/:id", :controller => 'changeset', :action => 'update', :id => /\d+/, :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/changeset/:id/close", :controller => 'changeset', :action => 'close', :id =>/\d+/
  map.connect "api/#{API_VERSION}/changesets", :controller => 'changeset', :action => 'query'
  
  map.connect "api/#{API_VERSION}/node/create", :controller => 'node', :action => 'create'
  map.connect "api/#{API_VERSION}/node/:id/ways", :controller => 'way', :action => 'ways_for_node', :id => /\d+/
  map.connect "api/#{API_VERSION}/node/:id/relations", :controller => 'relation', :action => 'relations_for_node', :id => /\d+/
  map.connect "api/#{API_VERSION}/node/:id/history", :controller => 'old_node', :action => 'history', :id => /\d+/
  map.connect "api/#{API_VERSION}/node/:id/:version", :controller => 'old_node', :action => 'version', :id => /\d+/, :version => /\d+/
  map.connect "api/#{API_VERSION}/node/:id", :controller => 'node', :action => 'read', :id => /\d+/, :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/node/:id", :controller => 'node', :action => 'update', :id => /\d+/, :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/node/:id", :controller => 'node', :action => 'delete', :id => /\d+/, :conditions => { :method => :delete }
  map.connect "api/#{API_VERSION}/nodes", :controller => 'node', :action => 'nodes', :id => nil
  
  map.connect "api/#{API_VERSION}/way/create", :controller => 'way', :action => 'create'
  map.connect "api/#{API_VERSION}/way/:id/history", :controller => 'old_way', :action => 'history', :id => /\d+/
  map.connect "api/#{API_VERSION}/way/:id/full", :controller => 'way', :action => 'full', :id => /\d+/
  map.connect "api/#{API_VERSION}/way/:id/relations", :controller => 'relation', :action => 'relations_for_way', :id => /\d+/
  map.connect "api/#{API_VERSION}/way/:id/:version", :controller => 'old_way', :action => 'version', :id => /\d+/, :version => /\d+/
  map.connect "api/#{API_VERSION}/way/:id", :controller => 'way', :action => 'read', :id => /\d+/, :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/way/:id", :controller => 'way', :action => 'update', :id => /\d+/, :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/way/:id", :controller => 'way', :action => 'delete', :id => /\d+/, :conditions => { :method => :delete }
  map.connect "api/#{API_VERSION}/ways", :controller => 'way', :action => 'ways', :id => nil

  map.connect "api/#{API_VERSION}/relation/create", :controller => 'relation', :action => 'create'
  map.connect "api/#{API_VERSION}/relation/:id/relations", :controller => 'relation', :action => 'relations_for_relation', :id => /\d+/
  map.connect "api/#{API_VERSION}/relation/:id/history", :controller => 'old_relation', :action => 'history', :id => /\d+/
  map.connect "api/#{API_VERSION}/relation/:id/full", :controller => 'relation', :action => 'full', :id => /\d+/
  map.connect "api/#{API_VERSION}/relation/:id/:version", :controller => 'old_relation', :action => 'version', :id => /\d+/, :version => /\d+/
  map.connect "api/#{API_VERSION}/relation/:id", :controller => 'relation', :action => 'read', :id => /\d+/, :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/relation/:id", :controller => 'relation', :action => 'update', :id => /\d+/, :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/relation/:id", :controller => 'relation', :action => 'delete', :id => /\d+/, :conditions => { :method => :delete }
  map.connect "api/#{API_VERSION}/relations", :controller => 'relation', :action => 'relations', :id => nil

  map.connect "api/#{API_VERSION}/map", :controller => 'api', :action => 'map'
  
  map.connect "api/#{API_VERSION}/trackpoints", :controller => 'api', :action => 'trackpoints'

  map.connect "api/#{API_VERSION}/changes", :controller => 'api', :action => 'changes'
  
  map.connect "api/#{API_VERSION}/search", :controller => 'search', :action => 'search_all'
  map.connect "api/#{API_VERSION}/ways/search", :controller => 'search', :action => 'search_ways'
  map.connect "api/#{API_VERSION}/relations/search", :controller => 'search', :action => 'search_relations'
  map.connect "api/#{API_VERSION}/nodes/search", :controller => 'search', :action => 'search_nodes'
  
  map.connect "api/#{API_VERSION}/user/details", :controller => 'user', :action => 'api_details'
  map.connect "api/#{API_VERSION}/user/preferences", :controller => 'user_preference', :action => 'read', :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/user/preferences/:preference_key", :controller => 'user_preference', :action => 'read_one', :conditions => { :method => :get }
  map.connect "api/#{API_VERSION}/user/preferences", :controller => 'user_preference', :action => 'update', :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/user/preferences/:preference_key", :controller => 'user_preference', :action => 'update_one', :conditions => { :method => :put }
  map.connect "api/#{API_VERSION}/user/preferences/:preference_key", :controller => 'user_preference', :action => 'delete_one', :conditions => { :method => :delete }
  map.connect "api/#{API_VERSION}/user/gpx_files", :controller => 'user', :action => 'api_gpx_files'
 
  map.connect "api/#{API_VERSION}/gpx/create", :controller => 'trace', :action => 'api_create'
  map.connect "api/#{API_VERSION}/gpx/:id/details", :controller => 'trace', :action => 'api_details'
  map.connect "api/#{API_VERSION}/gpx/:id/data", :controller => 'trace', :action => 'api_data'
  
  # AMF (ActionScript) API
  
  map.connect "api/#{API_VERSION}/amf/read", :controller =>'amf', :action =>'amf_read'
  map.connect "api/#{API_VERSION}/amf/write", :controller =>'amf', :action =>'amf_write'
  map.connect "api/#{API_VERSION}/swf/trackpoints", :controller =>'swf', :action =>'trackpoints'
  
  # Data browsing
  map.connect '/browse', :controller => 'changeset', :action => 'list'
  map.connect '/browse/start', :controller => 'browse', :action => 'start'
  map.connect '/browse/way/:id', :controller => 'browse', :action => 'way', :id => /\d+/
  map.connect '/browse/way/:id/history', :controller => 'browse', :action => 'way_history', :id => /\d+/
  map.connect '/browse/node/:id', :controller => 'browse', :action => 'node', :id => /\d+/
  map.connect '/browse/node/:id/history', :controller => 'browse', :action => 'node_history', :id => /\d+/
  map.connect '/browse/relation/:id', :controller => 'browse', :action => 'relation', :id => /\d+/
  map.connect '/browse/relation/:id/history', :controller => 'browse', :action => 'relation_history', :id => /\d+/
  map.changeset '/browse/changeset/:id', :controller => 'browse', :action => 'changeset', :id => /\d+/
  map.connect '/browse/changesets', :controller => 'changeset', :action => 'list'
  map.connect '/browse/changesets/feed', :controller => 'changeset', :action => 'list', :format => :atom
  
  # web site
  map.root :controller => 'site', :action => 'index'
  map.connect '/', :controller => 'site', :action => 'index'
  map.connect '/edit', :controller => 'site', :action => 'edit'
  map.connect '/copyright', :controller => 'site', :action => 'copyright'
  map.connect '/history', :controller => 'changeset', :action => 'list'
  map.connect '/history/feed', :controller => 'changeset', :action => 'list', :format => :atom
  map.connect '/export', :controller => 'site', :action => 'export'
  map.connect '/login', :controller => 'user', :action => 'login'
  map.connect '/logout', :controller => 'user', :action => 'logout'
  map.connect '/offline', :controller => 'site', :action => 'offline'
  map.connect '/key', :controller => 'site', :action => 'key'
  map.connect '/user/new', :controller => 'user', :action => 'new'
  map.connect '/user/save', :controller => 'user', :action => 'save'
  map.connect '/user/confirm', :controller => 'user', :action => 'confirm'
  map.connect '/user/confirm-email', :controller => 'user', :action => 'confirm_email'
  map.connect '/user/go_public', :controller => 'user', :action => 'go_public'
  map.connect '/user/reset-password', :controller => 'user', :action => 'reset_password'
  map.connect '/user/forgot-password', :controller => 'user', :action => 'lost_password'

  map.connect '/index.html', :controller => 'site', :action => 'index'
  map.connect '/edit.html', :controller => 'site', :action => 'edit'
  map.connect '/history.html', :controller => 'changeset', :action => 'list_bbox'
  map.connect '/export.html', :controller => 'site', :action => 'export'
  map.connect '/search.html', :controller => 'way_tag', :action => 'search'
  map.connect '/login.html', :controller => 'user', :action => 'login'
  map.connect '/logout.html', :controller => 'user', :action => 'logout'
  map.connect '/create-account.html', :controller => 'user', :action => 'new'
  map.connect '/forgot-password.html', :controller => 'user', :action => 'lost_password'

  # permalink
  map.connect '/go/:code', :controller => 'site', :action => 'permalink', :code => /[a-zA-Z0-9_@]+[=-]*/

  # traces  
  map.connect '/traces', :controller => 'trace', :action => 'list'
  map.connect '/traces/page/:page', :controller => 'trace', :action => 'list'
  map.connect '/traces/rss', :controller => 'trace', :action => 'georss'
  map.connect '/traces/tag/:tag', :controller => 'trace', :action => 'list'
  map.connect '/traces/tag/:tag/page/:page', :controller => 'trace', :action => 'list'
  map.connect '/traces/tag/:tag/rss', :controller => 'trace', :action => 'georss'
  map.connect '/traces/mine', :controller => 'trace', :action => 'mine'
  map.connect '/traces/mine/page/:page', :controller => 'trace', :action => 'mine'
  map.connect '/traces/mine/tag/:tag', :controller => 'trace', :action => 'mine'
  map.connect '/traces/mine/tag/:tag/page/:page', :controller => 'trace', :action => 'mine'
  map.connect '/trace/create', :controller => 'trace', :action => 'create'
  map.connect '/trace/:id/data', :controller => 'trace', :action => 'data'
  map.connect '/trace/:id/data.:format', :controller => 'trace', :action => 'data'
  map.connect '/trace/:id/edit', :controller => 'trace', :action => 'edit'
  map.connect '/trace/:id/delete', :controller => 'trace', :action => 'delete'
  map.connect '/user/:display_name/traces', :controller => 'trace', :action => 'list'
  map.connect '/user/:display_name/traces/page/:page', :controller => 'trace', :action => 'list'
  map.connect '/user/:display_name/traces/rss', :controller => 'trace', :action => 'georss'
  map.connect '/user/:display_name/traces/tag/:tag', :controller => 'trace', :action => 'list'
  map.connect '/user/:display_name/traces/tag/:tag/page/:page', :controller => 'trace', :action => 'list'
  map.connect '/user/:display_name/traces/tag/:tag/rss', :controller => 'trace', :action => 'georss'
  map.connect '/user/:display_name/traces/:id', :controller => 'trace', :action => 'view'
  map.connect '/user/:display_name/traces/:id/picture', :controller => 'trace', :action => 'picture'
  map.connect '/user/:display_name/traces/:id/icon', :controller => 'trace', :action => 'icon'

  # user pages
  map.connect '/user/:display_name', :controller => 'user', :action => 'view'
  map.connect '/user/:display_name/edits', :controller => 'changeset', :action => 'list'
  map.connect '/user/:display_name/edits/feed', :controller => 'changeset', :action => 'list', :format =>:atom
  map.connect '/user/:display_name/make_friend', :controller => 'user', :action => 'make_friend'
  map.connect '/user/:display_name/remove_friend', :controller => 'user', :action => 'remove_friend'
  map.connect '/user/:display_name/diary', :controller => 'diary_entry', :action => 'list'
  map.connect '/user/:display_name/diary/:id', :controller => 'diary_entry', :action => 'view', :id => /\d+/
  map.connect '/user/:display_name/diary/:id/newcomment', :controller => 'diary_entry', :action => 'comment', :id => /\d+/
  map.connect '/user/:display_name/diary/rss', :controller => 'diary_entry', :action => 'rss'
  map.connect '/user/:display_name/diary/:id/edit', :controller => 'diary_entry', :action => 'edit', :id => /\d+/
  map.connect '/user/:display_name/diary/:id/hide', :controller => 'diary_entry', :action => 'hide', :id => /\d+/
  map.connect '/user/:display_name/diary/:id/hidecomment/:comment', :controller => 'diary_entry', :action => 'hidecomment', :id => /\d+/, :comment => /\d+/
  map.connect '/user/:display_name/account', :controller => 'user', :action => 'account'
  map.connect '/user/:display_name/activate', :controller => 'user', :action => 'activate'
  map.connect '/user/:display_name/deactivate', :controller => 'user', :action => 'deactivate'
  map.connect '/user/:display_name/hide', :controller => 'user', :action => 'hide'
  map.connect '/user/:display_name/unhide', :controller => 'user', :action => 'unhide'
  map.connect '/user/:display_name/delete', :controller => 'user', :action => 'delete'
  map.connect '/diary/new', :controller => 'diary_entry', :action => 'new'
  map.connect '/diary', :controller => 'diary_entry', :action => 'list'
  map.connect '/diary/rss', :controller => 'diary_entry', :action => 'rss'
  map.connect '/diary/:language', :controller => 'diary_entry', :action => 'list'
  map.connect '/diary/:language/rss', :controller => 'diary_entry', :action => 'rss'

  
  # test pages
  map.connect '/test/populate/:table/:from/:count', :controller => 'test', :action => 'populate'
  map.connect '/test/populate/:table/:count', :controller => 'test', :action => 'populate', :from => 1

  # geocoder
  map.connect '/geocoder/search', :controller => 'geocoder', :action => 'search'
  map.connect '/geocoder/search_latlon', :controller => 'geocoder', :action => 'search_latlon'
  map.connect '/geocoder/search_us_postcode', :controller => 'geocoder', :action => 'search_us_postcode'
  map.connect '/geocoder/search_uk_postcode', :controller => 'geocoder', :action => 'search_uk_postcode'
  map.connect '/geocoder/search_ca_postcode', :controller => 'geocoder', :action => 'search_ca_postcode'
  map.connect '/geocoder/search_osm_namefinder', :controller => 'geocoder', :action => 'search_osm_namefinder'
  map.connect '/geocoder/search_osm_nominatim', :controller => 'geocoder', :action => 'search_osm_nominatim'
  map.connect '/geocoder/search_geonames', :controller => 'geocoder', :action => 'search_geonames'
  map.connect '/geocoder/description', :controller => 'geocoder', :action => 'description'
  map.connect '/geocoder/description_osm_namefinder', :controller => 'geocoder', :action => 'description_osm_namefinder'
  map.connect '/geocoder/description_osm_nominatim', :controller => 'geocoder', :action => 'description_osm_nominatim'
  map.connect '/geocoder/description_geonames', :controller => 'geocoder', :action => 'description_geonames'

  # export
  map.connect '/export/start', :controller => 'export', :action => 'start'
  map.connect '/export/finish', :controller => 'export', :action => 'finish'

  # messages
  map.connect '/user/:display_name/inbox', :controller => 'message', :action => 'inbox'
  map.connect '/user/:display_name/outbox', :controller => 'message', :action => 'outbox'
  map.connect '/message/new/:display_name', :controller => 'message', :action => 'new'
  map.connect '/message/read/:message_id', :controller => 'message', :action => 'read'
  map.connect '/message/mark/:message_id', :controller => 'message', :action => 'mark'
  map.connect '/message/reply/:message_id', :controller => 'message', :action => 'reply'
  map.connect '/message/delete/:message_id', :controller => 'message', :action => 'delete'

  # oauth admin pages (i.e: for setting up new clients, etc...)
  map.resources :oauth_clients, :path_prefix => '/user/:display_name'
  map.connect '/oauth/revoke', :controller => 'oauth', :action => 'revoke'
  map.authorize '/oauth/authorize', :controller => 'oauth', :action => 'oauthorize'
  map.request_token '/oauth/request_token', :controller => 'oauth', :action => 'request_token'
  map.access_token '/oauth/access_token', :controller => 'oauth', :action => 'access_token'
  map.test_request '/oauth/test_request', :controller => 'oauth', :action => 'test_request'

  # roles and banning pages
  map.connect '/user/:display_name/role/:role/grant', :controller => 'user_roles', :action => 'grant'
  map.connect '/user/:display_name/role/:role/revoke', :controller => 'user_roles', :action => 'revoke'
  map.connect '/user/:display_name/blocks', :controller => 'user_blocks', :action => 'blocks_on'
  map.connect '/user/:display_name/blocks_by', :controller => 'user_blocks', :action => 'blocks_by'
  map.resources :user_blocks, :as => 'blocks'
  map.connect '/blocks/:id/revoke', :controller => 'user_blocks', :action => 'revoke'
  map.connect '/blocks/new/:display_name', :controller => 'user_blocks', :action => 'new'

  # fall through
  map.connect ':controller/:id/:action'
  map.connect ':controller/:action'
end
