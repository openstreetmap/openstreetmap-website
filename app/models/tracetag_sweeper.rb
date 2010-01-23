class TracetagSweeper < ActionController::Caching::Sweeper
  observe Tracetag

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
    expire_action(:controller => 'trace', :action => 'list', :display_name => nil, :tag => record.tag)
    expire_action(:controller => 'trace', :action => 'list', :display_name => record.trace.user.display_name, :tag => record.tag)

    expire_action(:controller => 'trace', :action => 'georss', :display_name => nil, :tag => record.tag)
    expire_action(:controller => 'trace', :action => 'georss', :display_name => record.trace.user.display_name, :tag => record.tag)
  end
end
