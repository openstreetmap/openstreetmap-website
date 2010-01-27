class DiarySweeper < ActionController::Caching::Sweeper
  observe DiaryComment, DiaryEntry

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
    case
    when record.is_a?(DiaryEntry): entry = record
    when record.is_a?(DiaryComment): entry = record.diary_entry
    end

    expire_action(:controller => 'diary_entry', :action => 'view', :display_name => entry.user.display_name, :id => entry.id)

    expire_action(:controller => 'diary_entry', :action => 'list', :language => nil, :display_name => nil)
    expire_action(:controller => 'diary_entry', :action => 'list', :language => entry.language_code, :display_name => nil)
    expire_action(:controller => 'diary_entry', :action => 'list', :language => nil, :display_name => entry.user.display_name)

    expire_action(:controller => 'diary_entry', :action => 'rss', :language => nil, :display_name => nil)
    expire_action(:controller => 'diary_entry', :action => 'rss', :language => entry.language_code, :display_name => nil)
    expire_action(:controller => 'diary_entry', :action => 'rss', :language => nil, :display_name => entry.user.display_name)
  end
end
