require  "session_persistence/session_persistence"
ActionController::Base.class_eval { include SessionPersistence }
ActionController::Base.after_filter :_persist_session
