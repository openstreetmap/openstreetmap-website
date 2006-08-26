ActionController::Routing::Routes.draw do |map|
#  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect 'api/0.4/node/create', :controller => 'node', :action => 'create'
  map.connect 'api/0.4/node/:id/history', :controller => 'node', :action => 'history', :id => nil
  map.connect 'api/0.4/node/:id', :controller => 'node', :action => 'rest', :id => nil

  map.connect 'api/0.4/segment/create', :controller => 'segment', :action => 'create'
  map.connect 'api/0.4/segment/:id/history', :controller => 'segment', :action => 'history'
  map.connect 'api/0.4/segment/:id', :controller => 'segment', :action => 'rest'

  map.connect '/', :controller => 'site', :action => 'index'
  map.connect '/index.html', :controller => 'site', :action => 'index'
  map.connect '/edit.html', :controller => 'site', :action => 'edit'
  map.connect '/login.html', :controller => 'user', :action => 'login'
  map.connect '/logout.html', :controller => 'user', :action => 'logout'
  map.connect '/create-account.html', :controller => 'user', :action => 'new'

  map.connect ':controller/:action/:id'
end
