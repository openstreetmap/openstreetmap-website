ActionController::Routing::Routes.draw do |map|

  # API
  map.connect "api/#{API_VERSION}/node/create", :controller => 'node', :action => 'create'
  map.connect "api/#{API_VERSION}/node/:id/history", :controller => 'old_node', :action => 'history', :id => nil
  map.connect "api/#{API_VERSION}/node/:id", :controller => 'node', :action => 'rest', :id => nil 
  map.connect "api/#{API_VERSION}/nodes", :controller => 'node', :action => 'nodes', :id => nil
  
  map.connect "api/#{API_VERSION}/segment/create", :controller => 'segment', :action => 'create'
  map.connect "api/#{API_VERSION}/segment/:id/history", :controller => 'old_segment', :action => 'history'
  map.connect "api/#{API_VERSION}/segment/:id", :controller => 'segment', :action => 'rest'
  map.connect "api/#{API_VERSION}/segments", :controller => 'segment', :action => 'segments', :id => nil
  
  map.connect "api/#{API_VERSION}/way/create", :controller => 'way', :action => 'create'
  map.connect "api/#{API_VERSION}/way/:id/history", :controller => 'old_way', :action => 'history', :id => nil
  map.connect "api/#{API_VERSION}/way/:id", :controller => 'way', :action => 'rest', :id => nil
  map.connect "api/#{API_VERSION}/ways", :controller => 'way', :action => 'ways', :id => nil

  map.connect "api/#{API_VERSION}/map", :controller => 'api', :action => 'map'
  
  map.connect "api/#{API_VERSION}/search", :controller => 'search', :action => 'search_all'
  map.connect "api/#{API_VERSION}/way/search", :controller => 'search', :action => 'search_ways'
  map.connect "api/#{API_VERSION}/segment/search", :controller => 'search', :action => 'search_segments'
  map.connect "api/#{API_VERSION}/nodes/search", :controller => 'search', :action => 'search_nodes'
  
  map.connect "api/#{API_VERSION}/user/details", :controller => 'user', :action => 'api_details'
  map.connect "api/#{API_VERSION}/user/gpx_files", :controller => 'user', :action => 'api_gpx_files'
 
  map.connect "api/#{API_VERSION}/gpx/create/:filename/:description/:tags", :controller => 'trace', :action => 'api_create'
  map.connect "api/#{API_VERSION}/gpx/:id/details", :controller => 'trace', :action => 'api_details'
  map.connect "api/#{API_VERSION}/gpx/:id/data", :controller => 'trace', :action => 'api_data'
  
  # web site

  map.connect '/', :controller => 'site', :action => 'index'
  map.connect '/user/save', :controller => 'user', :action => 'save'
  map.connect '/user/confirm', :controller => 'user', :action => 'confirm'
  map.connect '/user/go_public', :controller => 'user', :action => 'go_public'
  map.connect '/index.html', :controller => 'site', :action => 'index'
  map.connect '/edit.html', :controller => 'site', :action => 'edit'
  map.connect '/search.html', :controller => 'way_tag', :action => 'search'
  map.connect '/login.html', :controller => 'user', :action => 'login'
  map.connect '/logout.html', :controller => 'user', :action => 'logout'
  map.connect '/create-account.html', :controller => 'user', :action => 'new'
  map.connect '/forgot-password.html', :controller => 'user', :action => 'lost_password'

  # traces  
  map.connect '/traces', :controller => 'trace', :action => 'list'
  map.connect '/traces/page/:page', :controller => 'trace', :action => 'list'
  map.connect '/traces/mine', :controller => 'trace', :action => 'mine'
  map.connect '/trace/create', :controller => 'trace', :action => 'create'
  map.connect '/traces/mine/page/:page', :controller => 'trace', :action => 'mine'
  map.connect '/traces/mine/tag/:tag', :controller => 'trace', :action => 'mine'
  map.connect '/traces/mine/tag/:tag/page/:page', :controller => 'trace', :action => 'mine'
  map.connect '/traces/rss', :controller => 'trace', :action => 'georss'
  map.connect '/user/:display_name/traces', :controller => 'trace', :action => 'list', :id => nil
  map.connect '/user/:display_name/traces/page/:page', :controller => 'trace', :action => 'list', :id => nil
  map.connect '/user/:display_name/traces/:id', :controller => 'trace', :action => 'view', :id => nil
  map.connect '/user/:display_name/traces/:id/picture', :controller => 'trace', :action => 'picture', :id => nil
  map.connect '/user/:display_name/traces/:id/icon', :controller => 'trace', :action => 'icon', :id => nil
  map.connect '/traces/tag/:tag', :controller => 'trace', :action => 'list', :id => nil
  map.connect '/traces/tag/:tag/page/:page', :controller => 'trace', :action => 'list', :id => nil

  # user pages
  map.connect '/user/:display_name', :controller => 'user', :action => 'view'
  map.connect '/user/:display_name/diary', :controller => 'user', :action => 'diary'
  map.connect '/user/:display_name/diary/newpost', :controller => 'diary_entry', :action => 'new'
  map.connect '/user/:display_name/edit', :controller => 'user', :action => 'edit'
  map.connect '/user/:display_name/account', :controller => 'user', :action => 'account'

  # test pages
  map.connect '/test/populate/:table/:from/:count', :controller => 'test', :action => 'populate'
  map.connect '/test/populate/:table/:count', :controller => 'test', :action => 'populate', :from => 1

  # fall through
  map.connect ':controller/:id/:action'
  map.connect ':controller/:action'
end
