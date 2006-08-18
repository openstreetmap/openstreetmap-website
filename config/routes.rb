ActionController::Routing::Routes.draw do |map|
#  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect 'api/0.4/node/create', :controller => 'node', :action => 'create'
  map.connect 'api/0.4/node/:id', :controller => 'node', :action => 'rest', :id => nil

 
#  map.connect 'api/0.4/segment/:id', :controller => 'segment', :action => 'rest'
#  map.connect 'api/0.4/segment/create', :controller => 'segment', :action => 'create'

#  map.connect 'api/0.4/way/:id', :controller => 'way', :action => 'rest'
#  map.connect 'api/0.4/way/create', :controller => 'way', :action => 'create'
 
  map.connect ':controller/:action/:id'
end
