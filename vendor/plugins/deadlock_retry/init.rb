require 'deadlock_retry'
ActiveRecord::Base.send :include, DeadlockRetry
