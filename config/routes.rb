OpenStreetMap::Application.routes.draw do
  # API
  match 'api/capabilities' => 'api#capabilities', :via => :get
  match 'api/0.6/capabilities' => 'api#capabilities', :via => :get
  match 'api/0.6/permissions' => 'api#permissions', :via => :get

  match 'api/0.6/changeset/create' => 'changeset#create', :via => :put
  match 'api/0.6/changeset/:id/upload' => 'changeset#upload', :via => :post, :id => /\d+/
  match 'api/0.6/changeset/:id/download' => 'changeset#download', :via => :get, :as => :changeset_download, :id => /\d+/
  match 'api/0.6/changeset/:id/expand_bbox' => 'changeset#expand_bbox', :via => :post, :id => /\d+/
  match 'api/0.6/changeset/:id' => 'changeset#read', :via => :get, :as => :changeset_read, :via => :get, :id => /\d+/
  match 'api/0.6/changeset/:id' => 'changeset#update', :via => :put, :id => /\d+/
  match 'api/0.6/changeset/:id/close' => 'changeset#close', :via => :put, :id => /\d+/
  match 'api/0.6/changesets' => 'changeset#query', :via => :get

  match 'api/0.6/node/create' => 'node#create', :via => :put
  match 'api/0.6/node/:id/ways' => 'way#ways_for_node', :via => :get, :id => /\d+/
  match 'api/0.6/node/:id/relations' => 'relation#relations_for_node', :via => :get, :id => /\d+/
  match 'api/0.6/node/:id/history' => 'old_node#history', :via => :get, :id => /\d+/
  match 'api/0.6/node/:id/:version/redact' => 'old_node#redact', :via => :post, :version => /\d+/, :id => /\d+/
  match 'api/0.6/node/:id/:version' => 'old_node#version', :via => :get, :id => /\d+/, :version => /\d+/
  match 'api/0.6/node/:id' => 'node#read', :via => :get, :id => /\d+/
  match 'api/0.6/node/:id' => 'node#update', :via => :put, :id => /\d+/
  match 'api/0.6/node/:id' => 'node#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/nodes' => 'node#nodes', :via => :get

  match 'api/0.6/way/create' => 'way#create', :via => :put
  match 'api/0.6/way/:id/history' => 'old_way#history', :via => :get, :id => /\d+/
  match 'api/0.6/way/:id/full' => 'way#full', :via => :get, :id => /\d+/
  match 'api/0.6/way/:id/relations' => 'relation#relations_for_way', :via => :get, :id => /\d+/
  match 'api/0.6/way/:id/:version/redact' => 'old_way#redact', :via => :post, :version => /\d+/, :id => /\d+/
  match 'api/0.6/way/:id/:version' => 'old_way#version', :via => :get, :id => /\d+/, :version => /\d+/
  match 'api/0.6/way/:id' => 'way#read', :via => :get, :id => /\d+/
  match 'api/0.6/way/:id' => 'way#update', :via => :put, :id => /\d+/
  match 'api/0.6/way/:id' => 'way#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/ways' => 'way#ways', :via => :get

  match 'api/0.6/relation/create' => 'relation#create', :via => :put
  match 'api/0.6/relation/:id/relations' => 'relation#relations_for_relation', :via => :get, :id => /\d+/
  match 'api/0.6/relation/:id/history' => 'old_relation#history', :via => :get, :id => /\d+/
  match 'api/0.6/relation/:id/full' => 'relation#full', :via => :get, :id => /\d+/
  match 'api/0.6/relation/:id/:version/redact' => 'old_relation#redact', :via => :post, :version => /\d+/, :id => /\d+/
  match 'api/0.6/relation/:id/:version' => 'old_relation#version', :via => :get, :id => /\d+/, :version => /\d+/
  match 'api/0.6/relation/:id' => 'relation#read', :via => :get, :id => /\d+/
  match 'api/0.6/relation/:id' => 'relation#update', :via => :put, :id => /\d+/
  match 'api/0.6/relation/:id' => 'relation#delete', :via => :delete, :id => /\d+/
  match 'api/0.6/relations' => 'relation#relations', :via => :get

  match 'api/0.6/map' => 'api#map', :via => :get

  match 'api/0.6/trackpoints' => 'api#trackpoints', :via => :get

  match 'api/0.6/changes' => 'api#changes', :via => :get

  match 'api/0.6/search' => 'search#search_all', :via => :get
  match 'api/0.6/ways/search' => 'search#search_ways', :via => :get
  match 'api/0.6/relations/search' => 'search#search_relations', :via => :get
  match 'api/0.6/nodes/search' => 'search#search_nodes', :via => :get

  match 'api/0.6/user/:id' => 'user#api_read', :via => :get, :id => /\d+/
  match 'api/0.6/user/details' => 'user#api_details', :via => :get
  match 'api/0.6/user/gpx_files' => 'user#api_gpx_files', :via => :get

  match 'api/0.6/user/preferences' => 'user_preference#read', :via => :get
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#read_one', :via => :get
  match 'api/0.6/user/preferences' => 'user_preference#update', :via => :put
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#update_one', :via => :put
  match 'api/0.6/user/preferences/:preference_key' => 'user_preference#delete_one', :via => :delete

  match 'api/0.6/gpx/create' => 'trace#api_create', :via => :post
  match 'api/0.6/gpx/:id' => 'trace#api_read', :via => :get, :id => /\d+/
  match 'api/0.6/gpx/:id' => 'trace#api_update', :via => :put, :id => /\d+/
  match 'api/0.6/gpx/:id' => 'trace#api_delete', :via => :delete, :id => /\d+/
  match 'api/0.6/gpx/:id/details' => 'trace#api_read', :via => :get, :id => /\d+/
  match 'api/0.6/gpx/:id/data' => 'trace#api_data', :via => :get
  
  # AMF (ActionScript) API
  match 'api/0.6/amf/read' => 'amf#amf_read', :via => :post
  match 'api/0.6/amf/write' => 'amf#amf_write', :via => :post
  match 'api/0.6/swf/trackpoints' => 'swf#trackpoints', :via => :get

  # Map notes API
  scope "api/0.6" do
    resources :notes, :except => [ :new, :edit, :update ], :constraints => { :id => /\d+/ }, :defaults => { :format => "xml" } do
      collection do
        get 'search'
        get 'feed', :defaults => { :format => "rss" }
      end

      member do
        post 'comment'
        post 'close'
      end
    end

    match 'notes/addPOIexec' => 'notes#create', :via => :post
    match 'notes/closePOIexec' => 'notes#close', :via => :post
    match 'notes/editPOIexec' => 'notes#comment', :via => :post
    match 'notes/getGPX' => 'notes#index', :via => :get, :format => "gpx"
    match 'notes/getRSSfeed' => 'notes#feed', :via => :get, :format => "rss"
  end

  # Data browsing
  match '/browse/start' => 'browse#start', :via => :get
  match '/browse/way/:id' => 'browse#way', :via => :get, :id => /\d+/
  match '/browse/way/:id/history' => 'browse#way_history', :via => :get, :id => /\d+/
  match '/browse/node/:id' => 'browse#node', :via => :get, :id => /\d+/
  match '/browse/node/:id/history' => 'browse#node_history', :via => :get, :id => /\d+/
  match '/browse/relation/:id' => 'browse#relation', :via => :get, :id => /\d+/
  match '/browse/relation/:id/history' => 'browse#relation_history', :via => :get, :id => /\d+/
  match '/browse/changeset/:id' => 'browse#changeset', :via => :get, :as => :changeset, :id => /\d+/
  match '/browse/note/:id' => 'browse#note', :via => :get, :id => /\d+/, :as => "browse_note"
  match '/browse/note/:id/comment' => 'notes#web_comment', :via => :post, :id => /\d+/
  match '/user/:display_name/edits' => 'changeset#list', :via => :get
  match '/user/:display_name/edits/feed' => 'changeset#feed', :via => :get, :format => :atom
  match '/user/:display_name/notes' => 'notes#mine', :via => :get
  match '/browse/friends' => 'changeset#list', :via => :get, :friends => true, :as => "friend_changesets"
  match '/browse/nearby' => 'changeset#list', :via => :get, :nearby => true, :as => "nearby_changesets"
  match '/browse/changesets' => 'changeset#list', :via => :get
  match '/browse/changesets/feed' => 'changeset#feed', :via => :get, :format => :atom
  match '/browse' => 'changeset#list', :via => :get

  # web site
  root :to => 'site#index', :via => [:get, :post]
  match '/edit' => 'site#edit', :via => :get
  match '/copyright/:copyright_locale' => 'site#copyright', :via => :get
  match '/copyright' => 'site#copyright', :via => :get
  match '/history' => 'changeset#list', :via => :get
  match '/history/feed' => 'changeset#feed', :via => :get, :format => :atom
  match '/export' => 'site#index', :export => true, :via => :get
  match '/login' => 'user#login', :via => [:get, :post]
  match '/logout' => 'user#logout', :via => [:get, :post]
  match '/offline' => 'site#offline', :via => :get
  match '/key' => 'site#key', :via => :get
  match '/id' => 'site#id', :via => :get
  match '/user/new' => 'user#new', :via => :get
  match '/user/terms' => 'user#terms', :via => [:get, :post]
  match '/user/save' => 'user#save', :via => :post
  match '/user/:display_name/confirm/resend' => 'user#confirm_resend', :via => :get
  match '/user/:display_name/confirm' => 'user#confirm', :via => [:get, :post]
  match '/user/confirm' => 'user#confirm', :via => [:get, :post]
  match '/user/confirm-email' => 'user#confirm_email', :via => [:get, :post]
  match '/user/go_public' => 'user#go_public', :via => :post
  match '/user/reset-password' => 'user#reset_password', :via => [:get, :post]
  match '/user/forgot-password' => 'user#lost_password', :via => [:get, :post]
  match '/user/suspended' => 'user#suspended', :via => :get

  match '/index.html' => 'site#index', :via => :get
  match '/create-account.html' => 'user#new', :via => :get
  match '/forgot-password.html' => 'user#lost_password', :via => :get

  # permalink
  match '/go/:code' => 'site#permalink', :via => :get, :code => /[a-zA-Z0-9_@~]+[=-]*/

  # rich text preview
  match '/preview/:format' => 'site#preview', :as => :preview

  # traces
  match '/user/:display_name/traces/tag/:tag/page/:page' => 'trace#list', :via => :get
  match '/user/:display_name/traces/tag/:tag' => 'trace#list', :via => :get
  match '/user/:display_name/traces/page/:page' => 'trace#list', :via => :get
  match '/user/:display_name/traces' => 'trace#list', :via => :get
  match '/user/:display_name/traces/tag/:tag/rss' => 'trace#georss', :via => :get
  match '/user/:display_name/traces/rss' => 'trace#georss', :via => :get
  match '/user/:display_name/traces/:id' => 'trace#view', :via => :get
  match '/user/:display_name/traces/:id/picture' => 'trace#picture', :via => :get
  match '/user/:display_name/traces/:id/icon' => 'trace#icon', :via => :get
  match '/traces/tag/:tag/page/:page' => 'trace#list', :via => :get
  match '/traces/tag/:tag' => 'trace#list', :via => :get
  match '/traces/page/:page' => 'trace#list', :via => :get
  match '/traces' => 'trace#list', :via => :get
  match '/traces/tag/:tag/rss' => 'trace#georss', :via => :get
  match '/traces/rss' => 'trace#georss', :via => :get
  match '/traces/mine/tag/:tag/page/:page' => 'trace#mine', :via => :get
  match '/traces/mine/tag/:tag' => 'trace#mine', :via => :get
  match '/traces/mine/page/:page' => 'trace#mine', :via => :get
  match '/traces/mine' => 'trace#mine', :via => :get
  match '/trace/create' => 'trace#create', :via => [:get, :post]
  match '/trace/:id/data' => 'trace#data', :via => :get
  match '/trace/:id/edit' => 'trace#edit', :via => [:get, :post, :put]
  match '/trace/:id/delete' => 'trace#delete', :via => :post

  # diary pages
  match '/diary/new' => 'diary_entry#new', :via => [:get, :post]
  match '/diary/friends' => 'diary_entry#list', :friends => true, :via => :get, :as => "friend_diaries"
  match '/diary/nearby' => 'diary_entry#list', :nearby => true, :via => :get, :as => "nearby_diaries"
  match '/user/:display_name/diary/rss' => 'diary_entry#rss', :via => :get, :format => :rss
  match '/diary/:language/rss' => 'diary_entry#rss', :via => :get, :format => :rss
  match '/diary/rss' => 'diary_entry#rss', :via => :get, :format => :rss
  match '/user/:display_name/diary/comments/:page' => 'diary_entry#comments', :via => :get, :page => /\d+/
  match '/user/:display_name/diary/comments/' => 'diary_entry#comments', :via => :get
  match '/user/:display_name/diary' => 'diary_entry#list', :via => :get
  match '/diary/:language' => 'diary_entry#list', :via => :get
  match '/diary' => 'diary_entry#list', :via => :get
  match '/user/:display_name/diary/:id' => 'diary_entry#view', :via => :get, :id => /\d+/
  match '/user/:display_name/diary/:id/newcomment' => 'diary_entry#comment', :via => :post, :id => /\d+/
  match '/user/:display_name/diary/:id/edit' => 'diary_entry#edit', :via => [:get, :post], :id => /\d+/
  match '/user/:display_name/diary/:id/hide' => 'diary_entry#hide', :via => :post, :id => /\d+/, :as => :hide_diary_entry
  match '/user/:display_name/diary/:id/hidecomment/:comment' => 'diary_entry#hidecomment', :via => :post, :id => /\d+/, :comment => /\d+/, :as => :hide_diary_comment

  # user pages
  match '/user/:display_name' => 'user#view', :via => :get, :as => "user"
  match '/user/:display_name/make_friend' => 'user#make_friend', :via => [:get, :post], :as => "make_friend"
  match '/user/:display_name/remove_friend' => 'user#remove_friend', :via => [:get, :post], :as => "remove_friend"
  match '/user/:display_name/account' => 'user#account', :via => [:get, :post]
  match '/user/:display_name/set_status' => 'user#set_status', :via => :get, :as => :set_status_user
  match '/user/:display_name/delete' => 'user#delete', :via => :get, :as => :delete_user

  # user lists
  match '/users' => 'user#list', :via => [:get, :post]
  match '/users/:status' => 'user#list', :via => [:get, :post]

  # geocoder
  match '/geocoder/search' => 'geocoder#search', :via => :post
  match '/geocoder/search_latlon' => 'geocoder#search_latlon', :via => :get
  match '/geocoder/search_us_postcode' => 'geocoder#search_us_postcode', :via => :get
  match '/geocoder/search_uk_postcode' => 'geocoder#search_uk_postcode', :via => :get
  match '/geocoder/search_ca_postcode' => 'geocoder#search_ca_postcode', :via => :get
  match '/geocoder/search_osm_namefinder' => 'geocoder#search_osm_namefinder', :via => :get
  match '/geocoder/search_osm_nominatim' => 'geocoder#search_osm_nominatim', :via => :get
  match '/geocoder/search_geonames' => 'geocoder#search_geonames', :via => :get
  match '/geocoder/description' => 'geocoder#description', :via => :post
  match '/geocoder/description_osm_namefinder' => 'geocoder#description_osm_namefinder', :via => :get
  match '/geocoder/description_osm_nominatim' => 'geocoder#description_osm_nominatim', :via => :get
  match '/geocoder/description_geonames' => 'geocoder#description_geonames', :via => :get

  # export
  match '/export/start' => 'export#start', :via => :get
  match '/export/finish' => 'export#finish', :via => :post
  match '/export/embed' => 'export#embed', :via => :get

  # messages
  match '/user/:display_name/inbox' => 'message#inbox', :via => :get, :as => "inbox"
  match '/user/:display_name/outbox' => 'message#outbox', :via => :get, :as => "outbox"
  match '/message/new/:display_name' => 'message#new', :via => [:get, :post], :as => "new_message"
  match '/message/read/:message_id' => 'message#read', :via => :get, :as => "read_message"
  match '/message/mark/:message_id' => 'message#mark', :via => :post, :as => "mark_message"
  match '/message/reply/:message_id' => 'message#reply', :via => [:get, :post], :as => "reply_message"
  match '/message/delete/:message_id' => 'message#delete', :via => :post, :as => "delete_message"

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
  match '/user/:display_name/role/:role/grant' => 'user_roles#grant', :via => :post, :as => "grant_role"
  match '/user/:display_name/role/:role/revoke' => 'user_roles#revoke', :via => :post, :as => "revoke_role"
  match '/user/:display_name/blocks' => 'user_blocks#blocks_on', :via => :get
  match '/user/:display_name/blocks_by' => 'user_blocks#blocks_by', :via => :get
  match '/blocks/new/:display_name' => 'user_blocks#new', :via => :get, :as => "new_user_block"
  resources :user_blocks
  match '/blocks/:id/revoke' => 'user_blocks#revoke', :via => [:get, :post], :as => "revoke_user_block"

  # redactions
  resources :redactions
end
