begin
  require 'active_record'
rescue LoadError
  if ENV['ACTIVERECORD_PATH'].nil?
    abort <<MSG
Please set the ACTIVERECORD_PATH environment variable to the directory
containing the active_record.rb file.
MSG
  else
    $LOAD_PATH.unshift << ENV['ACTIVERECORD_PATH']
    begin
      require 'active_record'
    rescue LoadError
      abort "ActiveRecord could not be found."
    end
  end
end

require 'test/unit'
require "#{File.dirname(__FILE__)}/../lib/deadlock_retry"

class MockModel
  def self.transaction(*objects, &block)
    block.call
  end

  def self.logger
    @logger ||= Logger.new(nil)
  end

  include DeadlockRetry
end

class DeadlockRetryTest < Test::Unit::TestCase
  DEADLOCK_ERROR = "MySQL::Error: Deadlock found when trying to get lock"
  TIMEOUT_ERROR = "MySQL::Error: Lock wait timeout exceeded"

  def test_no_errors
    assert_equal :success, MockModel.transaction { :success }
  end

  def test_no_errors_with_deadlock
    errors = [ DEADLOCK_ERROR ] * 3
    assert_equal :success, MockModel.transaction { raise ActiveRecord::StatementInvalid, errors.shift unless errors.empty?; :success }
    assert errors.empty?
  end

  def test_no_errors_with_lock_timeout
    errors = [ TIMEOUT_ERROR ] * 3
    assert_equal :success, MockModel.transaction { raise ActiveRecord::StatementInvalid, errors.shift unless errors.empty?; :success }
    assert errors.empty?
  end

  def test_error_if_limit_exceeded
    assert_raise(ActiveRecord::StatementInvalid) do
      MockModel.transaction { raise ActiveRecord::StatementInvalid, DEADLOCK_ERROR }
    end
  end

  def test_error_if_unrecognized_error
    assert_raise(ActiveRecord::StatementInvalid) do
      MockModel.transaction { raise ActiveRecord::StatementInvalid, "Something else" }
    end
  end
end
