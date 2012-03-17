class TraceSweeper < ActionController::Caching::Sweeper
  observe Trace

  def after_create(record)
    expire_cache_for(record)
  end

  def after_update(record)
    expire_cache_for(record)
  end

  def after_destroy(record)
    expire_cache_for(record)
  end

private

  def expire_cache_for(record)
    expire_action(:controller => 'trace', :action => 'view', :display_name => record.user.display_name, :id => record.id)

    expire_action(:controller => 'trace', :action => 'list', :display_name => nil, :tag => nil)
    expire_action(:controller => 'trace', :action => 'list', :display_name => record.user.display_name, :tag => nil)

    expire_action(:controller => 'trace', :action => 'georss', :display_name => nil, :tag => nil)
    expire_action(:controller => 'trace', :action => 'georss', :display_name => record.user.display_name, :tag => nil)
  end
end
