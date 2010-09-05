module SessionPersistence
  private
  
  # Override this method if you don't want to use session[:_remember_for].
  def session_persistence_key
    :_remember_for
  end

  # Persist the session.
  #
  #   session_expires_after 1.hour
  #   session_expires_after 2.weeks
  def session_expires_after(seconds)
    session[session_persistence_key] = seconds 
  end
  
  # Expire the session.
  def session_expires_automatically
    session.delete(session_persistence_key)
  end
  alias_method :expire_session, :session_expires_automatically
  
  def _persist_session
    if session[session_persistence_key]
      env["rack.session.options"][:expire_after] = session[session_persistence_key]
    end
  end
end
