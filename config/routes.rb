OpenStreetMap::Application.routes.draw do
  # API
  match 'api/capabilities' => 'api#capabilities'
  match 'api/0.6/capabilities' => 'api#capabilities'

  match 'api/0.6/changeset/create' => 'changeset#create'
  match 'api/0.6/changeset/:id/upload' => 'changeset#upload', :id => /\d+/
  match 'api/0.6/changeset/:id/download' => 'changeset#download', :as => :changeset_download, :id => /\d+/
  match 'api/0.6/changeset/:id/expand_bbox' => 'changeset#expand_bbox', :id => /\d+/
  match 'api/0.6/changeset/:id' => 'changeset#read', :as => :changeset_read, :via => :get, :id => /\d+/
  match 'api/0.6/changeset/:id' => 'changeset#update', :via => :put, :id => /\d+/
  match 'api/0.6/changeset/:id/close' => 'changeset#close', :id => /\d+/
  match 'api/0.6/changesets' => 'changeset#query', :id => nil

  match 'api/0.6/node/create' => 'node#create'
  match 'api/0.6/node/:id/ways' => 'way#ways_for_node', :id => /\d+/
  match 'api/0.6/node/:id/relations' => 'relation#relations_for_node', :id => /\d+/
  match 'api/0.6/node/:id/history' => 'old_node#history', :id => /\d+/
  match 'api/0.6/node/:id/:version' => 'old_node#version', :version => /\d+/, :id => /\d+/
  match 'api/0.6/node/:id' => 'node#read', :via => :get, :id => /\d+/
  match 'api/0.6/node/:id' => 'node#update', :via => :put, :id => /\d+/
  match 'api/0.6/node/:id' => 'node#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/nodes' => 'node#nodes', :id => nil

  match 'api/0.6/way/create' => 'way#create'
  match 'api/0.6/way/:id/history' => 'old_way#history', :id => /\d+/
  match 'api/0.6/way/:id/full' => 'way#full', :id => /\d+/
  match 'api/0.6/way/:id/relations' => 'relation#relations_for_way', :id => /\d+/
  match 'api/0.6/way/:id/:version' => 'old_way#version', :version => /\d+/, :id => /\d+/
  match 'api/0.6/way/:id' => 'way#read', :via => :get, :id => /\d+/
  match 'api/0.6/way/:id' => 'way#update', :via => :put, :id => /\d+/
  match 'api/0.6/way/:id' => 'way#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/ways' => 'way#ways', :id => nil

  match 'api/0.6/relation/create' => 'relation#create'
  match 'api/0.6/relation/:id/relations' => 'relation#relations_for_relation', :id => /\d+/
  match 'api/0.6/relation/:id/history' => 'old_relation#history', :id => /\d+/
  match 'api/0.6/relation/:id/full' => 'relation#full', :id => /\d+/
  match 'api/0.6/relation/:id/:version' => 'old_relation#version', :version => /\d+/, :id => /\d+/
  match 'api/0.6/relation/:id' => 'relation#read', :via => :get, :id => /\d+/
  match 'api/0.6/relation/:id' => 'relation#update', :via => :put, :id => /\d+/
  match 'api/0.6/relation/:id' => 'relation#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/relations' => 'relation#relations'

  match 'api/0.6/map' => 'api#map'

  match 'api/0.6/trackpoints' => 'api#trackpoints'

  match 'api/0.6/changes' => 'api#changes'

  match 'api/0.6/search' => 'search#search_all'
  match 'api/0.6/ways/search' => 'search#search_ways'
  match 'api/0.6/relations/search' => 'search#search_relations'
  match 'api/0.6/nodes/search' => 'search#search_nodes'

  match 'api/0.6/user/details' => 'user#api_details'
  match 'api/0.6/user/preferences' => 'user_preference#read', :via => :get
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#read_one', :via => :get
  match 'api/0.6/user/preferences' => 'user_preference#update', :via => :put
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#update_one', :via => :put
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#delete_one', :via => :delete
  match 'api/0.6/user/gpx_files' => 'user#api_gpx_files'

  match 'api/0.6/gpx/create' => 'trace#api_create'
  match 'api/0.6/gpx/:id' => 'trace#api_read', :via => :get, :id => /\d+/
  match 'api/0.6/gpx/:id' => 'trace#api_update', :via => :put, :id => /\d+/
  match 'api/0.6/gpx/:id' => 'trace#api_delete', :via => :delete, :id => /\d+/
  match 'api/0.6/gpx/:id/details' => 'trace#api_read', :id => /\d+/
  match 'api/0.6/gpx/:id/data' => 'trace#api_data'
  match 'api/0.6/gpx/:id/data.:format' => 'trace#api_data'
  
  # AMF (ActionScript) API

  match 'api/0.6/amf/read' => 'amf#amf_read'
  match 'api/0.6/amf/write' => 'amf#amf_write'
  match 'api/0.6/swf/trackpoints' => 'swf#trackpoints'

  # Data browsing
  match '/browse/start' => 'browse#start'
  match '/browse/way/:id' => 'browse#way', :id => /\d+/
  match '/browse/way/:id/history' => 'browse#way_history', :id => /\d+/
  match '/browse/node/:id' => 'browse#node', :id => /\d+/
  match '/browse/node/:id/history' => 'browse#node_history', :id => /\d+/
  match '/browse/relation/:id' => 'browse#relation', :id => /\d+/
  match '/browse/relation/:id/history' => 'browse#relation_history', :id => /\d+/
  match '/browse/changeset/:id' => 'browse#changeset', :as => :changeset, :id => /\d+/
  match '/user/:display_name/edits' => 'changeset#list'
  match '/user/:display_name/edits/feed' => 'changeset#feed', :format => :atom
  match '/browse/friends' => 'changeset#list', :friends => true
  match '/browse/nearby' => 'changeset#list', :nearby => true
  match '/browse/changesets' => 'changeset#list'
  match '/browse/changesets/feed' => 'changeset#feed', :format => :atom
  match '/browse' => 'changeset#list'

  # web site
  root :to => 'site#index'
  match '/edit' => 'site#edit'
  match '/copyright' => 'site#copyright'
  match '/copyright/:copyright_locale' => 'site#copyright'
  match '/history' => 'changeset#list'
  match '/history/feed' => 'changeset#feed', :format => :atom
  match '/export' => 'site#export'
  match '/login' => 'user#login'
  match '/logout' => 'user#logout'
  match '/offline' => 'site#offline'
  match '/key' => 'site#key'
  match '/user/new' => 'user#new'
  match '/user/terms' => 'user#terms'
  match '/user/save' => 'user#save'
  match '/user/:display_name/confirm/resend' => 'user#confirm_resend'
  match '/user/:display_name/confirm' => 'user#confirm'
  match '/user/confirm' => 'user#confirm'
  match '/user/confirm-email' => 'user#confirm_email'
  match '/user/go_public' => 'user#go_public'
  match '/user/reset-password' => 'user#reset_password'
  match '/user/forgot-password' => 'user#lost_password'
  match '/user/suspended' => 'user#suspended'

  match '/index.html' => 'site#index'
  match '/edit.html' => 'site#edit'
  match '/export.html' => 'site#export'
  match '/login.html' => 'user#login'
  match '/logout.html' => 'user#logout'
  match '/create-account.html' => 'user#new'
  match '/forgot-password.html' => 'user#lost_password'

  # permalink
  match '/go/:code' => 'site#permalink', :code => /[a-zA-Z0-9_@~]+[=-]*/

  # traces
  match '/user/:display_name/traces/tag/:tag/page/:page' => 'trace#list'
  match '/user/:display_name/traces/tag/:tag' => 'trace#list'
  match '/user/:display_name/traces/page/:page' => 'trace#list'
  match '/user/:display_name/traces' => 'trace#list'
  match '/user/:display_name/traces/tag/:tag/rss' => 'trace#georss'
  match '/user/:display_name/traces/rss' => 'trace#georss'
  match '/user/:display_name/traces/:id' => 'trace#view'
  match '/user/:display_name/traces/:id/picture' => 'trace#picture'
  match '/user/:display_name/traces/:id/icon' => 'trace#icon'
  match '/traces/tag/:tag/page/:page' => 'trace#list'
  match '/traces/tag/:tag' => 'trace#list'
  match '/traces/page/:page' => 'trace#list'
  match '/traces' => 'trace#list'
  match '/traces/tag/:tag/rss' => 'trace#georss'
  match '/traces/rss' => 'trace#georss'
  match '/traces/mine/tag/:tag/page/:page' => 'trace#mine'
  match '/traces/mine/tag/:tag' => 'trace#mine'
  match '/traces/mine/page/:page' => 'trace#mine'
  match '/traces/mine' => 'trace#mine'
  match '/trace/create' => 'trace#create'
  match '/trace/:id/data' => 'trace#data'
  match '/trace/:id/data.:format' => 'trace#data'
  match '/trace/:id/edit' => 'trace#edit'
  match '/trace/:id/delete' => 'trace#delete'

  # diary pages
  match '/diary/new' => 'diary_entry#new'
  match '/diary/friends' => 'diary_entry#list', :friends => true
  match '/diary/nearby' => 'diary_entry#list', :nearby => true  
  match '/user/:display_name/diary/rss' => 'diary_entry#rss', :format => :rss
  match '/diary/:language/rss' => 'diary_entry#rss', :format => :rss
  match '/diary/rss' => 'diary_entry#rss', :format => :rss
  match '/user/:display_name/diary' => 'diary_entry#list'
  match '/diary/:language' => 'diary_entry#list'
  match '/diary' => 'diary_entry#list'
  match '/user/:display_name/diary/:id' => 'diary_entry#view', :id => /\d+/
  match '/user/:display_name/diary/:id/newcomment' => 'diary_entry#comment', :id => /\d+/
  match '/user/:display_name/diary/:id/edit' => 'diary_entry#edit', :id => /\d+/
  match '/user/:display_name/diary/:id/hide' => 'diary_entry#hide', :id => /\d+/
  match '/user/:display_name/diary/:id/hidecomment/:comment' => 'diary_entry#hidecomment', :id => /\d+/, :comment => /\d+/

  # user pages
  match '/user/:display_name' => 'user#view'
  match '/user/:display_name/make_friend' => 'user#make_friend'
  match '/user/:display_name/remove_friend' => 'user#remove_friend'
  match '/user/:display_name/account' => 'user#account'
  match '/user/:display_name/set_status' => 'user#set_status'
  match '/user/:display_name/delete' => 'user#delete'

  # user lists
  match '/users' => 'user#list'
  match '/users/:status' => 'user#list'

  # test pages
  match '/test/populate/:table/:from/:count' => 'test#populate'
  match '/test/populate/:table/:count' => 'test#populate', :from => 1

  # geocoder
  match '/geocoder/search' => 'geocoder#search'
  match '/geocoder/search_latlon' => 'geocoder#search_latlon'
  match '/geocoder/search_us_postcode' => 'geocoder#search_us_postcode'
  match '/geocoder/search_uk_postcode' => 'geocoder#search_uk_postcode'
  match '/geocoder/search_ca_postcode' => 'geocoder#search_ca_postcode'
  match '/geocoder/search_osm_namefinder' => 'geocoder#search_osm_namefinder'
  match '/geocoder/search_osm_nominatim' => 'geocoder#search_osm_nominatim'
  match '/geocoder/search_geonames' => 'geocoder#search_geonames'
  match '/geocoder/description' => 'geocoder#description'
  match '/geocoder/description_osm_namefinder' => 'geocoder#description_osm_namefinder'
  match '/geocoder/description_osm_nominatim' => 'geocoder#description_osm_nominatim'
  match '/geocoder/description_geonames' => 'geocoder#description_geonames'

  # export
  match '/export/start' => 'export#start'
  match '/export/finish' => 'export#finish'

  # messages
  match '/user/:display_name/inbox' => 'message#inbox'
  match '/user/:display_name/outbox' => 'message#outbox'
  match '/message/new/:display_name' => 'message#new'
  match '/message/read/:message_id' => 'message#read'
  match '/message/mark/:message_id' => 'message#mark'
  match '/message/reply/:message_id' => 'message#reply'
  match '/message/delete/:message_id' => 'message#delete'

  # oauth admin pages (i.e: for setting up new clients, etc...)
  scope "/user/:display_name" do
    resources :oauth_clients
  end
  match '/oauth/revoke' => 'oauth#revoke'
  match '/oauth/authorize' => 'oauth#authorize', :as => :authorize
  match '/oauth/token' => 'oauth#token', :as => :token
  match '/oauth/request_token' => 'oauth#request_token', :as => :request_token
  match '/oauth/access_token' => 'oauth#access_token', :as => :access_token
  match '/oauth/test_request' => 'oauth#test_request', :as => :test_request

  # roles and banning pages
  match '/user/:display_name/role/:role/grant' => 'user_roles#grant'
  match '/user/:display_name/role/:role/revoke' => 'user_roles#revoke'
  match '/user/:display_name/blocks' => 'user_blocks#blocks_on'
  match '/user/:display_name/blocks_by' => 'user_blocks#blocks_by'
  match '/blocks/new/:display_name' => 'user_blocks#new'
  resources :user_blocks
  match '/blocks/:id/revoke' => 'user_blocks#revoke'

  # fall through
  match ':controller/:id/:action' => '#index'
  match ':controller/:action' => '#index'
end
