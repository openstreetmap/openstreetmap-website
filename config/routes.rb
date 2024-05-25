OpenStreetMap::Application.routes.draw do
  use_doorkeeper :scope => "oauth2" do
    controllers :authorizations => "oauth2_authorizations",
                :applications => "oauth2_applications",
                :authorized_applications => "oauth2_authorized_applications"
  end

  use_doorkeeper_openid_connect :scope => "oauth2" if Settings.key?(:doorkeeper_signing_key)

  # API
  namespace :api do
    get "capabilities" => "capabilities#show" # Deprecated, remove when 0.6 support is removed
    get "versions" => "versions#show"
  end

  scope "api/0.6", :module => :api do
    get "capabilities" => "capabilities#show"
    get "permissions" => "permissions#show"

    put "changeset/create" => "changesets#create"
    post "changeset/:id/upload" => "changesets#upload", :as => :changeset_upload, :id => /\d+/
    get "changeset/:id/download" => "changesets#download", :as => :changeset_download, :id => /\d+/
    get "changeset/:id" => "changesets#show", :as => :changeset_show, :id => /\d+/
    post "changeset/:id/subscribe" => "changesets#subscribe", :as => :api_changeset_subscribe, :id => /\d+/
    post "changeset/:id/unsubscribe" => "changesets#unsubscribe", :as => :api_changeset_unsubscribe, :id => /\d+/
    put "changeset/:id" => "changesets#update", :id => /\d+/
    put "changeset/:id/close" => "changesets#close", :as => :changeset_close, :id => /\d+/
    get "changesets" => "changesets#index"
    post "changeset/:id/comment" => "changeset_comments#create", :as => :changeset_comment, :id => /\d+/
    post "changeset/comment/:id/hide" => "changeset_comments#destroy", :as => :changeset_comment_hide, :id => /\d+/
    post "changeset/comment/:id/unhide" => "changeset_comments#restore", :as => :changeset_comment_unhide, :id => /\d+/

    put "node/create" => "nodes#create"
    get "node/:id/ways" => "ways#ways_for_node", :as => :node_ways, :id => /\d+/
    get "node/:id/relations" => "relations#relations_for_node", :as => :node_relations, :id => /\d+/
    get "node/:id/history" => "old_nodes#history", :as => :api_node_history, :id => /\d+/
    post "node/:id/:version/redact" => "old_nodes#redact", :as => :node_version_redact, :version => /\d+/, :id => /\d+/
    get "node/:id/:version" => "old_nodes#show", :as => :api_old_node, :id => /\d+/, :version => /\d+/
    get "node/:id" => "nodes#show", :as => :api_node, :id => /\d+/
    put "node/:id" => "nodes#update", :id => /\d+/
    delete "node/:id" => "nodes#delete", :id => /\d+/
    get "nodes" => "nodes#index"

    put "way/create" => "ways#create"
    get "way/:id/history" => "old_ways#history", :as => :api_way_history, :id => /\d+/
    get "way/:id/full" => "ways#full", :as => :way_full, :id => /\d+/
    get "way/:id/relations" => "relations#relations_for_way", :as => :way_relations, :id => /\d+/
    post "way/:id/:version/redact" => "old_ways#redact", :as => :way_version_redact, :version => /\d+/, :id => /\d+/
    get "way/:id/:version" => "old_ways#show", :as => :api_old_way, :id => /\d+/, :version => /\d+/
    get "way/:id" => "ways#show", :as => :api_way, :id => /\d+/
    put "way/:id" => "ways#update", :id => /\d+/
    delete "way/:id" => "ways#delete", :id => /\d+/
    get "ways" => "ways#index"

    put "relation/create" => "relations#create"
    get "relation/:id/relations" => "relations#relations_for_relation", :as => :relation_relations, :id => /\d+/
    get "relation/:id/history" => "old_relations#history", :as => :api_relation_history, :id => /\d+/
    get "relation/:id/full" => "relations#full", :as => :relation_full, :id => /\d+/
    post "relation/:id/:version/redact" => "old_relations#redact", :as => :relation_version_redact, :version => /\d+/, :id => /\d+/
    get "relation/:id/:version" => "old_relations#show", :as => :api_old_relation, :id => /\d+/, :version => /\d+/
    get "relation/:id" => "relations#show", :as => :api_relation, :id => /\d+/
    put "relation/:id" => "relations#update", :id => /\d+/
    delete "relation/:id" => "relations#delete", :id => /\d+/
    get "relations" => "relations#index"

    get "map" => "map#index"

    get "trackpoints" => "tracepoints#index"

    get "user/:id" => "users#show", :id => /\d+/, :as => :api_user
    get "user/details" => "users#details"
    get "user/gpx_files" => "users#gpx_files"
    get "users" => "users#index", :as => :api_users

    resources :user_preferences, :except => [:new, :create, :edit], :param => :preference_key, :path => "user/preferences", :controller => "user_preferences" do
      collection do
        put "" => "user_preferences#update_all", :as => ""
      end
    end

    post "gpx/create" => "traces#create"
    get "gpx/:id" => "traces#show", :as => :api_trace, :id => /\d+/
    put "gpx/:id" => "traces#update", :id => /\d+/
    delete "gpx/:id" => "traces#destroy", :id => /\d+/
    get "gpx/:id/details" => "traces#show", :id => /\d+/
    get "gpx/:id/data" => "traces#data", :as => :api_trace_data
  end

  namespace :api, :path => "api/0.6" do
    # Map notes API
    resources :notes, :except => [:new, :edit, :update], :id => /\d+/, :controller => "notes" do
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

    resources :user_blocks, :only => :show, :id => /\d+/, :controller => "user_blocks"
  end

  # Data browsing
  get "/way/:id" => "ways#show", :id => /\d+/, :as => :way
  get "/way/:id/history" => "old_ways#index", :id => /\d+/, :as => :way_history
  resources :old_ways, :path => "/way/:id/history", :id => /\d+/, :version => /\d+/, :param => :version, :only => :show
  get "/node/:id" => "nodes#show", :id => /\d+/, :as => :node
  get "/node/:id/history" => "old_nodes#index", :id => /\d+/, :as => :node_history
  resources :old_nodes, :path => "/node/:id/history", :id => /\d+/, :version => /\d+/, :param => :version, :only => :show
  get "/relation/:id" => "relations#show", :id => /\d+/, :as => :relation
  get "/relation/:id/history" => "old_relations#index", :id => /\d+/, :as => :relation_history
  resources :old_relations, :path => "/relation/:id/history", :id => /\d+/, :version => /\d+/, :param => :version, :only => :show
  resources :changesets, :path => "changeset", :id => /\d+/, :only => :show do
    match :subscribe, :unsubscribe, :on => :member, :via => [:get, :post]
  end
  get "/changeset/:id/comments/feed" => "changeset_comments#index", :as => :changeset_comments_feed, :id => /\d*/, :defaults => { :format => "rss" }
  resources :notes, :path => "note", :id => /\d+/, :only => [:show, :new]

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
  get "/communities_index" => "site#communities"
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
  scope :user, :as => "user" do
    get "forgot-password" => "passwords#new"
    post "forgot-password" => "passwords#create"
    get "reset-password" => "passwords#edit"
    post "reset-password" => "passwords#update"
  end
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
  get "/user/:display_name/traces/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/traces/tag/%{tag}")
  get "/user/:display_name/traces/tag/:tag" => "traces#index"
  get "/user/:display_name/traces/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/traces")
  get "/user/:display_name/traces" => "traces#index"
  get "/user/:display_name/traces/tag/:tag/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/user/:display_name/traces/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/user/:display_name/traces/:id" => "traces#show", :as => "show_trace"
  scope "/user/:display_name/traces/:trace_id", :module => :traces do
    get "picture" => "pictures#show", :as => "trace_picture"
    get "icon" => "icons#show", :as => "trace_icon"
  end
  get "/traces/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/tag/%{tag}")
  get "/traces/tag/:tag" => "traces#index"
  get "/traces/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces")
  get "/traces/tag/:tag/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/traces/rss" => "traces#georss", :defaults => { :format => :rss }
  get "/traces/mine/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/mine/tag/%{tag}")
  get "/traces/mine/tag/:tag" => "traces#mine"
  get "/traces/mine/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/mine")
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
  get "/user/:display_name/diary/comments/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/diary/comments")
  get "/user/:display_name/diary/comments" => "diary_comments#index", :as => :diary_comments
  get "/user/:display_name/diary" => "diary_entries#index"
  get "/diary/:language" => "diary_entries#index"
  scope "/user/:display_name" do
    resources :diary_entries, :path => "diary", :only => [:edit, :update, :show], :id => /\d+/
  end
  post "/user/:display_name/diary/:id/hide" => "diary_entries#hide", :id => /\d+/, :as => :hide_diary_entry
  post "/user/:display_name/diary/:id/unhide" => "diary_entries#unhide", :id => /\d+/, :as => :unhide_diary_entry
  match "/user/:display_name/diary/:id/subscribe" => "diary_entries#subscribe", :via => [:get, :post], :as => :diary_entry_subscribe, :id => /\d+/
  match "/user/:display_name/diary/:id/unsubscribe" => "diary_entries#unsubscribe", :via => [:get, :post], :as => :diary_entry_unsubscribe, :id => /\d+/
  post "/user/:display_name/diary/:id/comments" => "diary_comments#create", :id => /\d+/, :as => :comment_diary_entry
  post "/user/:display_name/diary/:id/comments/:comment/hide" => "diary_comments#hide", :id => /\d+/, :comment => /\d+/, :as => :hide_diary_comment
  post "/user/:display_name/diary/:id/comments/:comment/unhide" => "diary_comments#unhide", :id => /\d+/, :comment => /\d+/, :as => :unhide_diary_comment

  # user pages
  resources :users, :path => "user", :param => :display_name, :only => [:show, :destroy] do
    resources :communities, :only => [:index]
  end
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
  post "/geocoder/search_latlon" => "geocoder#search_latlon"
  post "/geocoder/search_osm_nominatim" => "geocoder#search_osm_nominatim"
  post "/geocoder/search_osm_nominatim_reverse" => "geocoder#search_osm_nominatim_reverse"

  # directions
  get "/directions" => "directions#search"

  # export
  post "/export/finish" => "export#finish"
  get "/export/embed" => "export#embed"

  # messages
  resources :messages, :only => [:create, :show, :destroy] do
    post :mark
    patch :unmute

    match :reply, :via => [:get, :post]
    collection do
      get :inbox
      get :muted
      get :outbox
    end
  end
  get "/user/:display_name/inbox", :to => redirect(:path => "/messages/inbox")
  get "/user/:display_name/outbox", :to => redirect(:path => "/messages/outbox")
  get "/message/new/:display_name" => "messages#new", :as => "new_message"
  get "/message/read/:message_id", :to => redirect(:path => "/messages/%{message_id}")

  # muting users
  scope "/user/:display_name" do
    resource :user_mute, :only => [:create, :destroy], :path => "mute"
  end
  resources :user_mutes, :only => [:index]

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
  match "/user/:display_name/blocks/revoke_all" => "user_blocks#revoke_all", :via => [:get, :post], :as => "revoke_all_user_blocks"

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

  # communities
  resources :communities do
    resources :community_links, :only => [:create, :index, :new]
    # TODO: Shorten these path names, like :event.
    get :community_members, :to => "community_members#index"
    get :community_events, :to => "events#index"
    resources :events, :only => [:show]
  end
  post "/communities/:id/step_up" => "communities#step_up", :as => :step_up, :id => /\d+/
  resources :community_links, :only => [:destroy, :edit, :update]
  resources :community_members, :only => [:create, :destroy, :edit, :new, :update]
  get "/community_members" => "community_members#create", :as => "login_to_join"
  resources :events
  resources :event_attendances

  # errors
  match "/400", :to => "errors#bad_request", :via => :all
  match "/403", :to => "errors#forbidden", :via => :all
  match "/404", :to => "errors#not_found", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
end
