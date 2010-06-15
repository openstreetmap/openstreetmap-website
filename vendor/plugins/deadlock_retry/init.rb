require 'deadlock_retry'

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, DeadlockRetry
end
