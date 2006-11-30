ActionController::Routing::Routes.draw do |map|

  # API
  API_VERSION = '0.4' # change this in envronment.rb too
  map.connect "api/#{API_VERSION}/node/create", :controller => 'node', :action => 'create'
  map.connect "api/#{API_VERSION}/node/:id/history", :controller => 'old_node', :action => 'history', :id => nil
  map.connect "api/#{API_VERSION}/node/:id", :controller => 'node', :action => 'rest', :id => nil

  map.connect "api/#{API_VERSION}/segment/create", :controller => 'segment', :action => 'create'
  map.connect "api/#{API_VERSION}/segment/:id/history", :controller => 'old_segment', :action => 'history'
  map.connect "api/#{API_VERSION}/segment/:id", :controller => 'segment', :action => 'rest'

  map.connect "api/#{API_VERSION}/way/create", :controller => 'way', :action => 'create'
  map.connect "api/#{API_VERSION}/way/:id/history", :controller => 'old_way', :action => 'history', :id => nil
  map.connect "api/#{API_VERSION}/way/:id", :controller => 'way', :action => 'rest', :id => nil

  map.connect "api/#{API_VERSION}/map", :controller => 'api', :action => 'map'
  
  # web site

  map.connect '/', :controller => 'site', :action => 'index'
  map.connect '/index.html', :controller => 'site', :action => 'index'
  map.connect '/edit.html', :controller => 'site', :action => 'edit'
  map.connect '/login.html', :controller => 'user', :action => 'login'
  map.connect '/logout.html', :controller => 'user', :action => 'logout'
  map.connect '/create-account.html', :controller => 'user', :action => 'new'
  map.connect '/forgot-password.html', :controller => 'user', :action => 'lost_password'
  
  map.connect '/traces', :controller => 'trace', :action => 'list'
  map.connect '/traces/mine', :controller => 'trace', :action => 'mine'
  map.connect '/traces/user/:user/:id', :controller => 'trace', :action => 'list', :id => nil

  map.connect ':controller/:action/:id'
end
