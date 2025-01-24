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
  end

  namespace :api, :path => "api/0.6" do
    resource :map, :only => :show

    resources :tracepoints, :path => "trackpoints", :only => :index

    resources :users, :only => :index
    resources :users, :path => "user", :id => /\d+/, :only => :show
    resources :user_traces, :path => "user/gpx_files", :module => :users, :controller => :traces, :only => :index
    get "user/details" => "users#details"

    resources :user_preferences, :except => [:new, :create, :edit], :param => :preference_key, :path => "user/preferences" do
      collection do
        put "" => "user_preferences#update_all", :as => ""
      end
    end

    resources :messages, :path => "user/messages", :constraints => { :id => /\d+/ }, :only => [:create, :show, :update, :destroy]
    namespace :messages, :path => "user/messages" do
      resource :inbox, :only => :show
      resource :outbox, :only => :show
    end
    post "/user/messages/:id" => "messages#update", :as => nil

    resources :traces, :path => "gpx", :only => [:create, :show, :update, :destroy], :id => /\d+/ do
      scope :module => :traces do
        resource :data, :only => :show
      end
    end
    post "gpx/create" => "traces#create", :id => /\d+/, :as => :trace_create
    get "gpx/:id/details" => "traces#show", :id => /\d+/, :as => :trace_details

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

      resource :subscription, :only => [:create, :destroy], :controller => "note_subscriptions"
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
    resource :subscription, :controller => :changeset_subscriptions, :only => [:show, :create, :destroy]
    namespace :changeset_comments, :as => :comments, :path => :comments do
      resource :feed, :only => :show, :defaults => { :format => "rss" }
    end
  end
  get "/changeset/:id/subscribe", :id => /\d+/, :to => redirect(:path => "/changeset/%{id}/subscription")
  get "/changeset/:id/unsubscribe", :id => /\d+/, :to => redirect(:path => "/changeset/%{id}/subscription")

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
  get "/communities" => "site#communities"
  get "/history" => "changesets#index"
  get "/history/feed" => "changesets#feed", :defaults => { :format => :atom }
  scope "/history" do
    namespace :changeset_comments, :path => :comments, :as => :changesets_comments do
      resource :feed, :only => :show, :defaults => { :format => "rss" }
    end
  end
  get "/export" => "site#export"
  get "/login" => "sessions#new"
  post "/login" => "sessions#create"
  match "/logout" => "sessions#destroy", :via => [:get, :post]
  get "/offline" => "site#offline"
  get "/key" => "site#key"
  get "/id" => "site#id"
  get "/query" => "browse#query"
  post "/user/:display_name/confirm/resend" => "confirmations#confirm_resend", :as => :user_confirm_resend
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
  resources :traces, :id => /\d+/, :except => [:show] do
    resource :data, :module => :traces, :only => :show
  end
  get "/user/:display_name/traces/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/traces/tag/%{tag}")
  get "/user/:display_name/traces/tag/:tag" => "traces#index"
  get "/user/:display_name/traces/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/traces")
  get "/user/:display_name/traces" => "traces#index"
  get "/user/:display_name/traces/:id" => "traces#show", :id => /\d+/, :as => "show_trace"
  scope "/user/:display_name/traces/:trace_id", :module => :traces, :trace_id => /\d+/ do
    get "picture" => "pictures#show", :as => "trace_picture"
    get "icon" => "icons#show", :as => "trace_icon"
  end
  get "/traces/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/tag/%{tag}")
  get "/traces/tag/:tag" => "traces#index"
  get "/traces/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces")
  get "/traces/mine/tag/:tag/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/mine/tag/%{tag}")
  get "/traces/mine/tag/:tag" => "traces#mine"
  get "/traces/mine/page/:page", :page => /[1-9][0-9]*/, :to => redirect(:path => "/traces/mine")
  get "/traces/mine" => "traces#mine"
  get "/trace/create", :to => redirect(:path => "/traces/new")
  get "/trace/:id/data", :format => false, :id => /\d+/, :to => redirect(:path => "/traces/%{id}/data")
  get "/trace/:id/data.:format", :id => /\d+/, :to => redirect(:path => "/traces/%{id}/data.%{format}")
  get "/trace/:id/edit", :id => /\d+/, :to => redirect(:path => "/traces/%{id}/edit")

  namespace :traces, :path => "" do
    resource :feed, :path => "(/user/:display_name)/traces(/tag/:tag)/rss", :only => :show, :defaults => { :format => :rss }
  end

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
  get "/user/:display_name/diary" => "diary_entries#index"
  get "/diary/:language" => "diary_entries#index"
  scope "/user/:display_name" do
    resources :diary_entries, :path => "diary", :only => [:edit, :update, :show], :id => /\d+/ do
      member do
        post :hide
        post :unhide
      end
    end
  end
  match "/user/:display_name/diary/:id/subscribe" => "diary_entries#subscribe", :via => [:get, :post], :as => :diary_entry_subscribe, :id => /\d+/
  match "/user/:display_name/diary/:id/unsubscribe" => "diary_entries#unsubscribe", :via => [:get, :post], :as => :diary_entry_unsubscribe, :id => /\d+/
  post "/user/:display_name/diary/:id/comments" => "diary_comments#create", :id => /\d+/, :as => :comment_diary_entry
  post "/diary_comments/:comment/hide" => "diary_comments#hide", :comment => /\d+/, :as => :hide_diary_comment
  post "/diary_comments/:comment/unhide" => "diary_comments#unhide", :comment => /\d+/, :as => :unhide_diary_comment

  # user pages
  get "/user/terms", :to => redirect(:path => "/account/terms")
  resources :users, :path => "user", :param => :display_name, :only => [:new, :create, :show] do
    resource :role, :controller => "user_roles", :path => "roles/:role", :only => [:create, :destroy]
    scope :module => :users do
      resources :diary_comments, :only => :index
      resources :changeset_comments, :only => :index
      resource :issued_blocks, :path => "blocks_by", :only => :show
      resource :received_blocks, :path => "blocks", :only => [:show, :edit, :destroy]
      resource :status, :only => :update
    end
  end
  get "/user/:display_name/account", :to => redirect(:path => "/account/edit")
  get "/user/:display_name/diary/comments(/:page)", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/diary_comments")

  resource :account, :only => [:edit, :update, :destroy] do
    scope :module => :accounts do
      resource :terms, :only => [:show, :update]
      resource :deletion, :only => :show
    end
  end

  resource :dashboard, :only => [:show]
  resource :preferences, :only => [:show, :update]
  get "/preferences/edit", :to => redirect(:path => "/preferences")
  resource :profile, :only => [:edit, :update]

  # friendships
  scope "/user/:display_name" do
    resource :follow, :only => [:create, :destroy, :show], :path => "follow"

    get "make_friend", :to => redirect("/user/%{display_name}/follow")
    get "remove_friend", :to => redirect("/user/%{display_name}/follow")
  end

  # user lists
  namespace :users do
    resource :list, :path => "(:status)", :only => [:show, :update]
  end

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
  resources :messages, :path_names => { :new => "new/:display_name" }, :id => /\d+/, :only => [:new, :create, :show, :destroy] do
    post :mark
    patch :unmute

    resource :reply, :module => :messages, :path_names => { :new => "new" }, :only => :new
  end
  namespace :messages, :path => "/messages" do
    resource :inbox, :only => :show
    resource :muted_inbox, :path => "muted", :only => :show
    resource :outbox, :only => :show
  end
  get "/user/:display_name/inbox", :to => redirect(:path => "/messages/inbox")
  get "/user/:display_name/outbox", :to => redirect(:path => "/messages/outbox")
  get "/message/new/:display_name", :to => redirect(:path => "/messages/new/%{display_name}")
  get "/message/read/:message_id", :to => redirect(:path => "/messages/%{message_id}")
  get "/messages/:message_id/reply", :to => redirect(:path => "/messages/%{message_id}/reply/new")

  # muting users
  scope "/user/:display_name" do
    resource :user_mute, :only => [:create, :destroy], :path => "mute"
  end
  resources :user_mutes, :only => [:index]

  # banning pages
  resources :user_blocks, :path_names => { :new => "new/:display_name" }

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
  match "/400", :to => "errors#bad_request", :via => :all
  match "/403", :to => "errors#forbidden", :via => :all
  match "/404", :to => "errors#not_found", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
end
