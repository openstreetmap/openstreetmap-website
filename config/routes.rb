OpenStreetMap::Application.routes.draw do
  # API
  get "api/capabilities" => "api#capabilities"

  scope "api/0.6" do
    get "capabilities" => "api#capabilities"
    get "permissions" => "api#permissions"

    put "changeset/create" => "changesets#create"
    post "changeset/:id/upload" => "changesets#upload", :id => /\d+/
    get "changeset/:id/download" => "changesets#download", :as => :changeset_download, :id => /\d+/
    post "changeset/:id/expand_bbox" => "changesets#expand_bbox", :id => /\d+/
    get "changeset/:id" => "changesets#show", :as => :changeset_show, :id => /\d+/
    post "changeset/:id/subscribe" => "changesets#subscribe", :as => :changeset_subscribe, :id => /\d+/
    post "changeset/:id/unsubscribe" => "changesets#unsubscribe", :as => :changeset_unsubscribe, :id => /\d+/
    put "changeset/:id" => "changesets#update", :id => /\d+/
    put "changeset/:id/close" => "changesets#close", :id => /\d+/
    get "changesets" => "changesets#query"
    post "changeset/:id/comment" => "changeset_comments#create", :as => :changeset_comment, :id => /\d+/
    post "changeset/comment/:id/hide" => "changeset_comments#destroy", :as => :changeset_comment_hide, :id => /\d+/
    post "changeset/comment/:id/unhide" => "changeset_comments#restore", :as => :changeset_comment_unhide, :id => /\d+/

    put "node/create" => "nodes#create"
    get "node/:id/ways" => "ways#ways_for_node", :id => /\d+/
    get "node/:id/relations" => "relations#relations_for_node", :id => /\d+/
    get "node/:id/history" => "old_nodes#history", :id => /\d+/
    post "node/:id/:version/redact" => "old_nodes#redact", :version => /\d+/, :id => /\d+/
    get "node/:id/:version" => "old_nodes#version", :id => /\d+/, :version => /\d+/
    get "node/:id" => "nodes#show", :id => /\d+/
    put "node/:id" => "nodes#update", :id => /\d+/
    delete "node/:id" => "nodes#delete", :id => /\d+/
    get "nodes" => "nodes#index"

    put "way/create" => "ways#create"
    get "way/:id/history" => "old_ways#history", :id => /\d+/
    get "way/:id/full" => "ways#full", :id => /\d+/
    get "way/:id/relations" => "relations#relations_for_way", :id => /\d+/
    post "way/:id/:version/redact" => "old_ways#redact", :version => /\d+/, :id => /\d+/
    get "way/:id/:version" => "old_ways#version", :id => /\d+/, :version => /\d+/
    get "way/:id" => "ways#show", :id => /\d+/
    put "way/:id" => "ways#update", :id => /\d+/
    delete "way/:id" => "ways#delete", :id => /\d+/
    get "ways" => "ways#index"

    put "relation/create" => "relations#create"
    get "relation/:id/relations" => "relations#relations_for_relation", :id => /\d+/
    get "relation/:id/history" => "old_relations#history", :id => /\d+/
    get "relation/:id/full" => "relations#full", :id => /\d+/
    post "relation/:id/:version/redact" => "old_relations#redact", :version => /\d+/, :id => /\d+/
    get "relation/:id/:version" => "old_relations#version", :id => /\d+/, :version => /\d+/
    get "relation/:id" => "relations#show", :id => /\d+/
    put "relation/:id" => "relations#update", :id => /\d+/
    delete "relation/:id" => "relations#delete", :id => /\d+/
    get "relations" => "relations#index"

    get "map" => "api#map"

    get "trackpoints" => "api#trackpoints"

    get "changes" => "api#changes"

    get "search" => "search#search_all", :as => "api_search"
    get "ways/search" => "search#search_ways"
    get "relations/search" => "search#search_relations"
    get "nodes/search" => "search#search_nodes"

    get "user/:id" => "users#api_read", :id => /\d+/
    get "user/details" => "users#api_details"
    get "user/gpx_files" => "users#api_gpx_files"
    get "users" => "users#api_users", :as => :api_users

    get "user/preferences" => "user_preferences#read"
    get "user/preferences/:preference_key" => "user_preferences#read_one"
    put "user/preferences" => "user_preferences#update"
    put "user/preferences/:preference_key" => "user_preferences#update_one"
    delete "user/preferences/:preference_key" => "user_preferences#delete_one"

    post "gpx/create" => "traces#api_create"
    get "gpx/:id" => "traces#api_read", :id => /\d+/
    put "gpx/:id" => "traces#api_update", :id => /\d+/
    delete "gpx/:id" => "traces#api_delete", :id => /\d+/
    get "gpx/:id/details" => "traces#api_read", :id => /\d+/
    get "gpx/:id/data" => "traces#api_data"

    # AMF (ActionScript) API
    post "amf/read" => "amf#amf_read"
    post "amf/write" => "amf#amf_write"
    get "swf/trackpoints" => "swf#trackpoints"

    # Map notes API
    resources :notes, :except => [:new, :edit, :update], :constraints => { :id => /\d+/ }, :defaults => { :format => "xml" } do
      collection do
        get "search"
        get "feed", :defaults => { :format => "rss" }
      end

      member do
        post "comment"
        post "close"
        post "reopen"
      end
    end

    post "notes/addPOIexec" => "notes#create"
    post "notes/closePOIexec" => "notes#close"
    post "notes/editPOIexec" => "notes#comment"
    get "notes/getGPX" => "notes#index", :format => "gpx"
    get "notes/getRSSfeed" => "notes#feed", :format => "rss"

    # third party API keys
    get "third_party_services/keys" => "third_party_services#retrieve_keys"
  end

  # Data browsing
  get "/way/:id" => "browse#way", :id => /\d+/, :as => :way
  get "/way/:id/history" => "browse#way_history", :id => /\d+/
  get "/node/:id" => "browse#node", :id => /\d+/, :as => :node
  get "/node/:id/history" => "browse#node_history", :id => /\d+/
  get "/relation/:id" => "browse#relation", :id => /\d+/, :as => :relation
  get "/relation/:id/history" => "browse#relation_history", :id => /\d+/
  get "/changeset/:id" => "browse#changeset", :as => :changeset, :id => /\d+/
  get "/changeset/:id/comments/feed" => "changeset_comments#index", :as => :changeset_comments_feed, :id => /\d*/, :defaults => { :format => "rss" }
  get "/note/:id" => "browse#note", :id => /\d+/, :as => "browse_note"
  get "/note/new" => "browse#new_note"
  get "/user/:display_name/history" => "changesets#index"
  get "/user/:display_name/history/feed" => "changesets#feed", :defaults => { :format => :atom }
  get "/user/:display_name/notes" => "notes#mine"
  get "/history/friends" => "changesets#index", :friends => true, :as => "friend_changesets", :defaults => { :format => :html }
  get "/history/nearby" => "changesets#index", :nearby => true, :as => "nearby_changesets", :defaults => { :format => :html }

  get "/browse/way/:id",                :to => redirect(:path => "/way/%{id}")
  get "/browse/way/:id/history",        :to => redirect(:path => "/way/%{id}/history")
  get "/browse/node/:id",               :to => redirect(:path => "/node/%{id}")
  get "/browse/node/:id/history",       :to => redirect(:path => "/node/%{id}/history")
  get "/browse/relation/:id",           :to => redirect(:path => "/relation/%{id}")
  get "/browse/relation/:id/history",   :to => redirect(:path => "/relation/%{id}/history")
  get "/browse/changeset/:id",          :to => redirect(:path => "/changeset/%{id}")
  get "/browse/note/:id",               :to => redirect(:path => "/note/%{id}")
  get "/user/:display_name/edits",      :to => redirect(:path => "/user/%{display_name}/history")
  get "/user/:display_name/edits/feed", :to => redirect(:path => "/user/%{display_name}/history/feed")
  get "/browse/friends",                :to => redirect(:path => "/history/friends")
  get "/browse/nearby",                 :to => redirect(:path => "/history/nearby")
  get "/browse/changesets/feed",        :to => redirect(:path => "/history/feed")
  get "/browse/changesets",             :to => redirect(:path => "/history")
  get "/browse",                        :to => redirect(:path => "/history")

  # web site
  root :to => "site#index", :via => [:get, :post]
  get "/edit" => "site#edit"
  get "/copyright/:copyright_locale" => "site#copyright"
  get "/copyright" => "site#copyright"
  get "/welcome" => "site#welcome"
  get "/fixthemap" => "site#fixthemap"
  get "/help" => "site#help"
  get "/about" => "site#about"
  get "/history" => "changesets#index"
  get "/history/feed" => "changesets#feed", :defaults => { :format => :atom }
  get "/history/comments/feed" => "changeset_comments#index", :as => :changesets_comments_feed, :defaults => { :format => "rss" }
  get "/export" => "site#export"
  match "/login" => "users#login", :via => [:get, :post]
  match "/logout" => "users#logout", :via => [:get, :post]
  get "/offline" => "site#offline"
  get "/key" => "site#key"
  get "/id" => "site#id"
  get "/query" => "browse#query"
  get "/user/new" => "users#new"
  post "/user/new" => "users#create"
  get "/user/terms" => "users#terms"
  post "/user/save" => "users#save"
  get "/user/:display_name/confirm/resend" => "users#confirm_resend"
  match "/user/:display_name/confirm" => "users#confirm", :via => [:get, :post]
  match "/user/confirm" => "users#confirm", :via => [:get, :post]
  match "/user/confirm-email" => "users#confirm_email", :via => [:get, :post]
  post "/user/go_public" => "users#go_public"
  match "/user/reset-password" => "users#reset_password", :via => [:get, :post]
  match "/user/forgot-password" => "users#lost_password", :via => [:get, :post]
  get "/user/suspended" => "users#suspended"

  get "/index.html", :to => redirect(:path => "/")
  get "/create-account.html", :to => redirect(:path => "/user/new")
  get "/forgot-password.html", :to => redirect(:path => "/user/forgot-password")

  # omniauth
  get "/auth/failure" => "users#auth_failure"
  match "/auth/:provider/callback" => "users#auth_success", :via => [:get, :post], :as => :auth_success
  match "/auth/:provider" => "users#auth", :via => [:get, :post], :as => :auth

  # permalink
  get "/go/:code" => "site#permalink", :code => /[a-zA-Z0-9_@~]+[=-]*/

  # rich text preview
  post "/preview/:type" => "site#preview", :as => :preview

  # traces
  resources :traces, :except => [:show]
  get "/user/:display_name/traces/tag/:tag/page/:page" => "traces#index", :page => /[1-9][0-9]*/
  get "/user/:display_name/traces/tag/:tag" => "traces#index"
  get "/user/:display_name/traces/page/:page" => "traces#index", :page => /[1-9][0-9]*/
  get "/user/:display_name/traces" => "traces#index"
  get "/user/:display_name/traces/tag/:tag/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/user/:display_name/traces/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/user/:display_name/traces/:id" => "traces#show"
  get "/user/:display_name/traces/:id/picture" => "traces#picture"
  get "/user/:display_name/traces/:id/icon" => "traces#icon"
  get "/traces/tag/:tag/page/:page" => "traces#index", :page => /[1-9][0-9]*/
  get "/traces/tag/:tag" => "traces#index"
  get "/traces/page/:page" => "traces#index", :page => /[1-9][0-9]*/
  get "/traces/tag/:tag/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/traces/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/traces/mine/tag/:tag/page/:page" => "traces#mine", :page => /[1-9][0-9]*/
  get "/traces/mine/tag/:tag" => "traces#mine"
  get "/traces/mine/page/:page" => "traces#mine"
  get "/traces/mine" => "traces#mine"
  get "/trace/create", :to => redirect(:path => "/traces/new")
  get "/trace/:id/data" => "traces#data", :id => /\d+/, :as => "trace_data"
  get "/trace/:id/edit", :to => redirect(:path => "/traces/%{id}/edit")
  post "/trace/:id/delete" => "traces#delete", :id => /\d+/

  # diary pages
  match "/diary/new" => "diary_entries#new", :via => [:get, :post]
  get "/diary/friends" => "diary_entries#index", :friends => true, :as => "friend_diaries"
  get "/diary/nearby" => "diary_entries#index", :nearby => true, :as => "nearby_diaries"
  get "/user/:display_name/diary/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/diary/:language/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/diary/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/user/:display_name/diary/comments/:page" => "diary_entries#comments", :page => /[1-9][0-9]*/
  get "/user/:display_name/diary/comments/" => "diary_entries#comments"
  get "/user/:display_name/diary" => "diary_entries#index"
  get "/diary/:language" => "diary_entries#index"
  get "/diary" => "diary_entries#index"
  get "/user/:display_name/diary/:id" => "diary_entries#show", :id => /\d+/, :as => :diary_entry
  post "/user/:display_name/diary/:id/newcomment" => "diary_entries#comment", :id => /\d+/
  match "/user/:display_name/diary/:id/edit" => "diary_entries#edit", :via => [:get, :post], :id => /\d+/
  post "/user/:display_name/diary/:id/hide" => "diary_entries#hide", :id => /\d+/, :as => :hide_diary_entry
  post "/user/:display_name/diary/:id/hidecomment/:comment" => "diary_entries#hidecomment", :id => /\d+/, :comment => /\d+/, :as => :hide_diary_comment
  post "/user/:display_name/diary/:id/subscribe" => "diary_entries#subscribe", :as => :diary_entry_subscribe, :id => /\d+/
  post "/user/:display_name/diary/:id/unsubscribe" => "diary_entries#unsubscribe", :as => :diary_entry_unsubscribe, :id => /\d+/

  # user pages
  get "/user/:display_name" => "users#show", :as => "user"
  match "/user/:display_name/make_friend" => "users#make_friend", :via => [:get, :post], :as => "make_friend"
  match "/user/:display_name/remove_friend" => "users#remove_friend", :via => [:get, :post], :as => "remove_friend"
  match "/user/:display_name/account" => "users#account", :via => [:get, :post]
  get "/user/:display_name/set_status" => "users#set_status", :as => :set_status_user
  get "/user/:display_name/delete" => "users#delete", :as => :delete_user

  # user lists
  match "/users" => "users#index", :via => [:get, :post]
  match "/users/:status" => "users#index", :via => [:get, :post]

  # geocoder
  get "/search" => "geocoder#search"
  get "/geocoder/search_latlon" => "geocoder#search_latlon"
  get "/geocoder/search_ca_postcode" => "geocoder#search_ca_postcode"
  get "/geocoder/search_osm_nominatim" => "geocoder#search_osm_nominatim"
  get "/geocoder/search_geonames" => "geocoder#search_geonames"
  get "/geocoder/search_osm_nominatim_reverse" => "geocoder#search_osm_nominatim_reverse"
  get "/geocoder/search_geonames_reverse" => "geocoder#search_geonames_reverse"

  # directions
  get "/directions" => "directions#search"

  # export
  post "/export/finish" => "export#finish"
  get "/export/embed" => "export#embed"

  # messages
  resources :messages, :only => [:create, :show, :destroy] do
    post :mark
    match :reply, :via => [:get, :post]
    collection do
      get :inbox
      get :outbox
    end
  end
  get "/user/:display_name/inbox", :to => redirect(:path => "/messages/inbox")
  get "/user/:display_name/outbox", :to => redirect(:path => "/messages/outbox")
  get "/message/new/:display_name" => "messages#new", :as => "new_message"
  get "/message/read/:message_id", :to => redirect(:path => "/messages/%{message_id}")

  resources :third_party_keys
  resources :third_party_services

  # oauth admin pages (i.e: for setting up new clients, etc...)
  scope "/user/:display_name" do
    resources :oauth_clients
  end
  match "/oauth/revoke" => "oauth#revoke", :via => [:get, :post]
  match "/oauth/authorize" => "oauth#authorize", :via => [:get, :post], :as => :authorize
  get "/oauth/token" => "oauth#token", :as => :token
  match "/oauth/request_token" => "oauth#request_token", :via => [:get, :post], :as => :request_token
  match "/oauth/access_token" => "oauth#access_token", :via => [:get, :post], :as => :access_token
  get "/oauth/test_request" => "oauth#test_request", :as => :test_request

  # roles and banning pages
  post "/user/:display_name/role/:role/grant" => "user_roles#grant", :as => "grant_role"
  post "/user/:display_name/role/:role/revoke" => "user_roles#revoke", :as => "revoke_role"
  get "/user/:display_name/blocks" => "user_blocks#blocks_on"
  get "/user/:display_name/blocks_by" => "user_blocks#blocks_by"
  get "/blocks/new/:display_name" => "user_blocks#new", :as => "new_user_block"
  resources :user_blocks
  match "/blocks/:id/revoke" => "user_blocks#revoke", :via => [:get, :post], :as => "revoke_user_block"

  # issues and reports
  resources :issues do
    resources :comments, :controller => :issue_comments
    member do
      post "resolve"
      post "assign"
      post "ignore"
      post "reopen"
    end
  end

  resources :reports

  # redactions
  resources :redactions

  # errors
  match "/403", :to => "errors#forbidden", :via => :all
  match "/404", :to => "errors#not_found", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
end
