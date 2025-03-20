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

    post "changeset/:id/upload" => "changesets#upload", :as => :changeset_upload, :id => /\d+/
    put "changeset/:id/close" => "changesets#close", :as => :changeset_close, :id => /\d+/
  end

  namespace :api, :path => "api/0.6" do
    resources :changesets, :only => [:index, :create]
    resources :changesets, :path => "changeset", :id => /\d+/, :only => [:show, :update] do
      resource :download, :module => :changesets, :only => :show
      resource :subscription, :controller => :changeset_subscriptions, :only => [:create, :destroy]
      resources :changeset_comments, :path => "comment", :only => :create
    end
    put "changeset/create" => "changesets#create", :as => nil
    post "changeset/:changeset_id/subscribe" => "changeset_subscriptions#create", :changeset_id => /\d+/, :as => nil
    post "changeset/:changeset_id/unsubscribe" => "changeset_subscriptions#destroy", :changeset_id => /\d+/, :as => nil

    resources :changeset_comments, :id => /\d+/, :only => :index do
      resource :visibility, :module => :changeset_comments, :only => [:create, :destroy]
    end
    post "changeset/comment/:changeset_comment_id/unhide" => "changeset_comments/visibilities#create", :changeset_comment_id => /\d+/, :as => nil
    post "changeset/comment/:changeset_comment_id/hide" => "changeset_comments/visibilities#destroy", :changeset_comment_id => /\d+/, :as => nil

    resources :nodes, :only => [:index, :create]
    resources :nodes, :path => "node", :id => /\d+/, :only => [:show, :update, :destroy] do
      scope :module => :nodes do
        resources :ways, :only => :index
        resources :relations, :only => :index
      end
      resources :versions, :path => "history", :controller => :old_nodes, :only => :index
      resource :version, :path => ":version", :version => /\d+/, :controller => :old_nodes, :only => :show do
        resource :redaction, :module => :old_nodes, :only => [:create, :destroy]
      end
    end
    put "node/create" => "nodes#create", :as => nil
    post "node/:node_id/:version/redact" => "old_nodes/redactions#create", :node_id => /\d+/, :version => /\d+/, :allow_delete => true, :as => nil

    resources :ways, :only => [:index, :create]
    resources :ways, :path => "way", :id => /\d+/, :only => [:show, :update, :destroy] do
      member do
        get :full, :action => :show, :full => true, :as => nil
      end
      scope :module => :ways do
        resources :relations, :only => :index
      end
      resources :versions, :path => "history", :controller => :old_ways, :only => :index
      resource :version, :path => ":version", :version => /\d+/, :controller => :old_ways, :only => :show do
        resource :redaction, :module => :old_ways, :only => [:create, :destroy]
      end
    end
    put "way/create" => "ways#create", :as => nil
    post "way/:way_id/:version/redact" => "old_ways/redactions#create", :way_id => /\d+/, :version => /\d+/, :allow_delete => true, :as => nil

    resources :relations, :only => [:index, :create]
    resources :relations, :path => "relation", :id => /\d+/, :only => [:show, :update, :destroy] do
      member do
        get :full, :action => :show, :full => true, :as => nil
      end
      scope :module => :relations do
        resources :relations, :only => :index
      end
      resources :versions, :path => "history", :controller => :old_relations, :only => :index
      resource :version, :path => ":version", :version => /\d+/, :controller => :old_relations, :only => :show do
        resource :redaction, :module => :old_relations, :only => [:create, :destroy]
      end
    end
    put "relation/create" => "relations#create", :as => nil
    post "relation/:relation_id/:version/redact" => "old_relations/redactions#create", :relation_id => /\d+/, :version => /\d+/, :allow_delete => true, :as => nil

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

    resources :user_blocks, :only => [:show, :create], :id => /\d+/, :controller => "user_blocks"
    namespace :user_blocks, :path => "user/blocks" do
      resource :active_list, :path => "active", :only => :show
    end
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
  resource :map_key, :path => "key", :only => :show
  get "/id" => "site#id"
  resource :feature_query, :path => "query", :only => :show
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
  get "/user/:display_name/account", :to => redirect(:path => "/account")
  get "/user/:display_name/diary/comments(/:page)", :page => /[1-9][0-9]*/, :to => redirect(:path => "/user/%{display_name}/diary_comments")

  resource :account, :only => [:show, :update, :destroy] do
    scope :module => :accounts do
      resource :terms, :only => [:show, :update]
      resource :pd_declaration, :only => [:show, :create]
      resource :deletion, :only => :show
      resource :home, :only => :show
    end
  end
  get "/account/edit", :to => redirect(:path => "/account"), :as => nil

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
    scope :module => :messages do
      resource :reply, :path_names => { :new => "new" }, :only => :new
      resource :read_mark, :only => [:create, :destroy]
      resource :mute, :only => :destroy
    end
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
    resources :reporters, :module => :issues, :only => :index
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
