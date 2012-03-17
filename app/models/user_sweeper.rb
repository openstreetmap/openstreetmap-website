class UserSweeper < ActionController::Caching::Sweeper
  observe User

  def before_update(record)
    expire_cache_for(User.find(record.id), record)
  end

  def before_destroy(record)
    expire_cache_for(record, nil)
  end

private

  def expire_cache_for(old_record, new_record)
    if old_record and
        (new_record.nil? or
         old_record.visible? != new_record.visible? or
         old_record.display_name != new_record.display_name or
         old_record.image.fingerprint != new_record.image.fingerprint)
      old_record.diary_entries.each do |entry|
        expire_action(:controller => 'diary_entry', :action => 'view', :display_name => old_record.display_name, :id => entry.id)
        expire_action(:controller => 'diary_entry', :action => 'list', :language => entry.language_code, :display_name => nil)
        expire_action(:controller => 'diary_entry', :action => 'rss', :format => :rss, :language => entry.language_code, :display_name => nil)
      end

      old_record.diary_comments.each do |comment|
        expire_action(:controller => 'diary_entry', :action => 'view', :display_name => comment.diary_entry.user.display_name, :id => comment.diary_entry.id)
      end

      expire_action(:controller => 'diary_entry', :action => 'list', :language => nil, :display_name => nil)
      expire_action(:controller => 'diary_entry', :action => 'list', :language => nil, :display_name => old_record.display_name)

      expire_action(:controller => 'diary_entry', :action => 'rss', :format => :rss, :language => nil, :display_name => nil)
      expire_action(:controller => 'diary_entry', :action => 'rss', :format => :rss, :language => nil, :display_name => old_record.display_name)

      old_record.traces.each do |trace|
        expire_action(:controller => 'trace', :action => 'view', :display_name => old_record.display_name, :id => trace.id)

        trace.tags.each do |tag|
          expire_action(:controller => 'trace', :action => 'list', :display_name => nil, :tag => tag.tag)
          expire_action(:controller => 'trace', :action => 'list', :display_name => old_record.display_name, :tag => tag.tag)

          expire_action(:controller => 'trace', :action => 'georss', :display_name => nil, :tag => tag.tag)
          expire_action(:controller => 'trace', :action => 'georss', :display_name => old_record.display_name, :tag => tag.tag)
        end
      end

      expire_action(:controller => 'trace', :action => 'list', :display_name => nil, :tag => nil)
      expire_action(:controller => 'trace', :action => 'list', :display_name => old_record.display_name, :tag => nil)

      expire_action(:controller => 'trace', :action => 'georss', :display_name => nil, :tag => nil)
      expire_action(:controller => 'trace', :action => 'georss', :display_name => old_record.display_name, :tag => nil)
    end
  end
end
