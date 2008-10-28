# An ActiveRecord class which corresponds to the database table
# +sessions+. Functions +find_session+, +create_session+,
# +update_session+ and +destroy+ constitute the interface to class
# +SqlSessionStore+.

class SqlSession < ActiveRecord::Base
  # this class should not be reloaded
  def self.reloadable?
    false
  end

  # retrieve session data for a given +session_id+ from the database,
  # return nil if no such session exists
  def self.find_session(session_id)
    find :first, :conditions => "session_id='#{session_id}'"
  end

  # create a new session with given +session_id+ and +data+
  def self.create_session(session_id, data)
    new(:session_id => session_id, :data => data)
  end

  # update session data and store it in the database
  def update_session(data)
    update_attribute('data', data)
  end
end
