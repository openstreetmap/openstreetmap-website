require 'deadlock_retry'

if defined?(ActionRecord::Base)
  ActiveRecord::Base.send :include, DeadlockRetry
end
