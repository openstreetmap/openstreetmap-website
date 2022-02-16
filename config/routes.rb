OpenStreetMap::Application.routes.draw do
  use_doorkeeper :scope => "oauth2" do
    controllers :authorizations => "oauth2_authorizations",
                :applications => "oauth2_applications",
                :authorized_applications => "oauth2_authorized_applications"
  end

  # API
  namespace :api do
    get "capabilities" => "capabilities#show" # Deprecated, remove when 0.6 support is removed
    get "versions" => "versions#show"
  end

  scope "api/0.6" do
    get "capabilities" => "api/capabilities#show"
    get "permissions" => "api/permissions#show"

    put "changeset/create" => "api/changesets#create"
    post "changeset/:id/upload" => "api/changesets#upload", :as => :changeset_upload, :id => /\d+/
    get "changeset/:id/download" => "api/changesets#download", :as => :changeset_download, :id => /\d+/
    get "changeset/:id" => "api/changesets#show", :as => :changeset_show, :id => /\d+/
    post "changeset/:id/subscribe" => "api/changesets#subscribe", :as => :changeset_subscribe, :id => /\d+/
    post "changeset/:id/unsubscribe" => "api/changesets#unsubscribe", :as => :changeset_unsubscribe, :id => /\d+/
    put "changeset/:id" => "api/changesets#update", :id => /\d+/
    put "changeset/:id/close" => "api/changesets#close", :as => :changeset_close, :id => /\d+/
    get "changesets" => "api/changesets#query"
    post "changeset/:id/comment" => "api/changeset_comments#create", :as => :changeset_comment, :id => /\d+/
    post "changeset/comment/:id/hide" => "api/changeset_comments#destroy", :as => :changeset_comment_hide, :id => /\d+/
    post "changeset/comment/:id/unhide" => "api/changeset_comments#restore", :as => :changeset_comment_unhide, :id => /\d+/

    put "node/create" => "api/nodes#create"
    get "node/:id/ways" => "api/ways#ways_for_node", :as => :node_ways, :id => /\d+/
    get "node/:id/relations" => "api/relations#relations_for_node", :as => :node_relations, :id => /\d+/
    get "node/:id/history" => "api/old_nodes#history", :as => :api_node_history, :id => /\d+/
    post "node/:id/:version/redact" => "api/old_nodes#redact", :as => :node_version_redact, :version => /\d+/, :id => /\d+/
    get "node/:id/:version" => "api/old_nodes#version", :as => :node_version, :id => /\d+/, :version => /\d+/
    get "node/:id" => "api/nodes#show", :as => :api_node, :id => /\d+/
    put "node/:id" => "api/nodes#update", :id => /\d+/
    delete "node/:id" => "api/nodes#delete", :id => /\d+/
    get "nodes" => "api/nodes#index"

    put "way/create" => "api/ways#create"
    get "way/:id/history" => "api/old_ways#history", :as => :api_way_history, :id => /\d+/
    get "way/:id/full" => "api/ways#full", :as => :way_full, :id => /\d+/
    get "way/:id/relations" => "api/relations#relations_for_way", :as => :way_relations, :id => /\d+/
    post "way/:id/:version/redact" => "api/old_ways#redact", :as => :way_version_redact, :version => /\d+/, :id => /\d+/
    get "way/:id/:version" => "api/old_ways#version", :as => :way_version, :id => /\d+/, :version => /\d+/
    get "way/:id" => "api/ways#show", :as => :api_way, :id => /\d+/
    put "way/:id" => "api/ways#update", :id => /\d+/
    delete "way/:id" => "api/ways#delete", :id => /\d+/
    get "ways" => "api/ways#index"

    put "relation/create" => "api/relations#create"
    get "relation/:id/relations" => "api/relations#relations_for_relation", :as => :relation_relations, :id => /\d+/
    get "relation/:id/history" => "api/old_relations#history", :as => :api_relation_history, :id => /\d+/
    get "relation/:id/full" => "api/relations#full", :as => :relation_full, :id => /\d+/
    post "relation/:id/:version/redact" => "api/old_relations#redact", :as => :relation_version_redact, :version => /\d+/, :id => /\d+/
    get "relation/:id/:version" => "api/old_relations#version", :as => :relation_version, :id => /\d+/, :version => /\d+/
    get "relation/:id" => "api/relations#show", :as => :api_relation, :id => /\d+/
    put "relation/:id" => "api/relations#update", :id => /\d+/
    delete "relation/:id" => "api/relations#delete", :id => /\d+/
    get "relations" => "api/relations#index"

    get "map" => "api/map#index"

    get "trackpoints" => "api/tracepoints#index"

    get "user/:id" => "api/users#show", :id => /\d+/, :as => :api_user
    get "user/details" => "api/users#details"
    get "user/gpx_files" => "api/users#gpx_files"
    get "users" => "api/users#index", :as => :api_users

    resources :user_preferences, :except => [:new, :create, :edit], :param => :preference_key, :path => "user/preferences", :controller => "api/user_preferences" do
      collection do
        put "" => "api/user_preferences#update_all", :as => ""
      end
    end

    post "gpx/create" => "api/traces#create"
    get "gpx/:id" => "api/traces#show", :as => :api_trace, :id => /\d+/
    put "gpx/:id" => "api/traces#update", :id => /\d+/
    delete "gpx/:id" => "api/traces#destroy", :id => /\d+/
    get "gpx/:id/details" => "api/traces#show", :id => /\d+/
    get "gpx/:id/data" => "api/traces#data", :as => :api_trace_data

    # Map notes API
    resources :notes, :except => [:new, :edit, :update], :constraints => { :id => /\d+/ }, :defaults => { :format => "xml" }, :controller => "api/notes" do
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

    post "notes/addPOIexec" => "api/notes#create"
    post "notes/closePOIexec" => "api/notes#close"
    post "notes/editPOIexec" => "api/notes#comment"
    get "notes/getGPX" => "api/notes#index", :format => "gpx"
    get "notes/getRSSfeed" => "api/notes#feed", :format => "rss"
  end

  # Data browsing
  get "/way/:id" => "browse#way", :id => /\d+/, :as => :way
  get "/way/:id/history" => "browse#way_history", :id => /\d+/, :as => :way_history
  get "/node/:id" => "browse#node", :id => /\d+/, :as => :node
  get "/node/:id/history" => "browse#node_history", :id => /\d+/, :as => :node_history
  get "/relation/:id" => "browse#relation", :id => /\d+/, :as => :relation
  get "/relation/:id/history" => "browse#relation_history", :id => /\d+/, :as => :relation_history
  get "/changeset/:id" => "browse#changeset", :as => :changeset, :id => /\d+/
  get "/changeset/:id/comments/feed" => "changeset_comments#index", :as => :changeset_comments_feed, :id => /\d*/, :defaults => { :format => "rss" }
  get "/note/:id" => "browse#note", :id => /\d+/, :as => "browse_note"
  get "/note/new" => "browse#new_note"
  get "/user/:display_name/history" => "changesets#index"
  get "/user/:display_name/history/feed" => "changesets#feed", :defaults => { :format => :atom }
  get "/user/:display_name/notes" => "notes#index", :as => :user_notes
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
  get "/about/:about_locale" => "site#about"
  get "/about" => "site#about"
  get "/history" => "changesets#index"
  get "/history/feed" => "changesets#feed", :defaults => { :format => :atom }
  get "/history/comments/feed" => "changeset_comments#index", :as => :changesets_comments_feed, :defaults => { :format => "rss" }
  get "/export" => "site#export"
  get "/login" => "sessions#new"
  post "/login" => "sessions#create"
  match "/logout" => "sessions#destroy", :via => [:get, :post]
  get "/offline" => "site#offline"
  get "/key" => "site#key"
  get "/id" => "site#id"
  get "/query" => "browse#query"
  get "/user/new" => "users#new"
  post "/user/new" => "users#create"
  get "/user/terms" => "users#terms"
  post "/user/save" => "users#save"
  get "/user/:display_name/confirm/resend" => "confirmations#confirm_resend", :as => :user_confirm_resend
  match "/user/:display_name/confirm" => "confirmations#confirm", :via => [:get, :post]
  match "/user/confirm" => "confirmations#confirm", :via => [:get, :post]
  match "/user/confirm-email" => "confirmations#confirm_email", :via => [:get, :post]
  post "/user/go_public" => "users#go_public"
  match "/user/reset-password" => "passwords#reset_password", :via => [:get, :post], :as => :user_reset_password
  match "/user/forgot-password" => "passwords#lost_password", :via => [:get, :post], :as => :user_forgot_password
  get "/user/suspended" => "users#suspended"

  get "/index.html", :to => redirect(:path => "/")
  get "/create-account.html", :to => redirect(:path => "/user/new")
  get "/forgot-password.html", :to => redirect(:path => "/user/forgot-password")

  # omniauth
  get "/auth/failure" => "users#auth_failure"
  match "/auth/:provider/callback" => "users#auth_success", :via => [:get, :post], :as => :auth_success
  match "/auth/:provider" => "users#auth", :via => [:post, :patch], :as => :auth

  # permalink
  get "/go/:code" => "site#permalink", :code => /[a-zA-Z0-9_@~]+[=-]*/, :as => :permalink

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
  get "/user/:display_name/traces/:id" => "traces#show", :as => "show_trace"
  get "/user/:display_name/traces/:id/picture" => "traces#picture", :as => "trace_picture"
  get "/user/:display_name/traces/:id/icon" => "traces#icon", :as => "trace_icon"
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

  # diary pages
  resources :diary_entries, :path => "diary", :only => [:new, :create, :index] do
    collection do
      get "friends" => "diary_entries#index", :friends => true
      get "nearby" => "diary_entries#index", :nearby => true
    end
  end
  get "/user/:display_name/diary/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/diary/:language/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/diary/rss" => "diary_entries#rss", :defaults => { :format => :rss }
  get "/user/:display_name/diary/comments/:page" => "diary_entries#comments", :page => /[1-9][0-9]*/
  get "/user/:display_name/diary/comments/" => "diary_entries#comments", :as => :diary_comments
  get "/user/:display_name/diary" => "diary_entries#index"
  get "/diary/:language" => "diary_entries#index"
  scope "/user/:display_name" do
    resources :diary_entries, :path => "diary", :only => [:edit, :update, :show]
  end
  post "/user/:display_name/diary/:id/newcomment" => "diary_entries#comment", :id => /\d+/, :as => :comment_diary_entry
  post "/user/:display_name/diary/:id/hide" => "diary_entries#hide", :id => /\d+/, :as => :hide_diary_entry
  post "/user/:display_name/diary/:id/unhide" => "diary_entries#unhide", :id => /\d+/, :as => :unhide_diary_entry
  post "/user/:display_name/diary/:id/hidecomment/:comment" => "diary_entries#hidecomment", :id => /\d+/, :comment => /\d+/, :as => :hide_diary_comment
  post "/user/:display_name/diary/:id/unhidecomment/:comment" => "diary_entries#unhidecomment", :id => /\d+/, :comment => /\d+/, :as => :unhide_diary_comment
  post "/user/:display_name/diary/:id/subscribe" => "diary_entries#subscribe", :as => :diary_entry_subscribe, :id => /\d+/
  post "/user/:display_name/diary/:id/unsubscribe" => "diary_entries#unsubscribe", :as => :diary_entry_unsubscribe, :id => /\d+/

  # user pages
  resources :users, :path => "user", :param => :display_name, :only => [:show, :destroy]
  get "/user/:display_name/account", :to => redirect(:path => "/account/edit")
  post "/user/:display_name/set_status" => "users#set_status", :as => :set_status_user

  resource :account, :only => [:edit, :update, :destroy]

  namespace :account do
    resource :deletion, :only => [:show]
  end
  resource :dashboard, :only => [:show]
  resource :preferences, :only => [:show, :edit, :update]
  resource :profile, :only => [:edit, :update]

  # friendships
  match "/user/:display_name/make_friend" => "friendships#make_friend", :via => [:get, :post], :as => "make_friend"
  match "/user/:display_name/remove_friend" => "friendships#remove_friend", :via => [:get, :post], :as => "remove_friend"

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
  get "/user/:display_name/blocks" => "user_blocks#blocks_on", :as => "user_blocks_on"
  get "/user/:display_name/blocks_by" => "user_blocks#blocks_by", :as => "user_blocks_by"
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
