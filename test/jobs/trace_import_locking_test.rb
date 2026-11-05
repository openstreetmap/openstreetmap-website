# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

# TraceImporterJob and TraceDestroyerJob coordinate through row locks on the
# trace, which only conflict between separate connections with committed
# data, so these tests don't run inside a transaction and clean up after
# themselves instead.
class TraceImportLockingTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @trace = create(:trace, :fixture => "a", :inserted => false)
  end

  def teardown
    Trace.find_by(:id => @trace.id)&.destroy
    ActiveStorage::Blob.unattached.find_each(&:purge)
    User.where(:id => @trace.user_id).delete_all
  end

  def test_destroy_waits_for_import
    while_importing do
      with_lock_timeout do
        assert_raises ActiveRecord::LockWaitTimeout do
          TraceDestroyerJob.new.perform(Trace.find(@trace.id))
        end
      end
    end

    assert_predicate @trace.reload, :inserted?
  end

  def test_mark_deleted_does_not_wait_for_import
    # Deleting a trace marks it as not visible straight away, which mustn't
    # wait for the import, hence the key share lock
    while_importing do
      with_lock_timeout do
        Trace.find(@trace.id).update!(:visible => false)
      end
    end

    assert_not_predicate @trace.reload, :visible?
  end

  def test_destroy_during_import
    destroyer = nil

    while_importing do |importer_pid|
      pids = Queue.new

      destroyer = Thread.new do
        Trace.connection_pool.with_connection do |connection|
          pids << connection.select_value("SELECT pg_backend_pid()")
          TraceDestroyerJob.new.perform(Trace.find(@trace.id))
        end
      end

      destroyer_pid = pids.pop(:timeout => 10)
      wait_until { !destroyer.alive? || blocked_by?(destroyer_pid, importer_pid) }

      assert_predicate destroyer, :alive?, "destroyer should wait for the import to finish"
    end

    # Raises any error from the destroyer, such as a foreign key violation
    # if it deleted the points before taking its lock
    destroyer.value

    assert_not Trace.exists?(@trace.id)
    assert_equal 0, Tracepoint.where(:gpx_id => @trace.id).count
    assert_equal 0, ActiveStorage::Attachment.where(:record_type => "Trace", :record_id => @trace.id).count
  end

  private

  # Imports the trace in another thread, and yields the backend pid of the
  # import's connection while it is paused after inserting the points
  def while_importing
    paused = Queue.new
    resume = Queue.new
    import = Tracepoint.method(:import!)

    pause = lambda do |*args, **kwargs|
      import.call(*args, **kwargs).tap do
        paused << Tracepoint.with_connection { |c| c.select_value("SELECT pg_backend_pid()") }
        resume.pop
      end
    end

    Tracepoint.stub(:import!, pause) do
      importer = Thread.new do
        Trace.connection_pool.with_connection do
          TraceImporterJob.new.perform(Trace.find(@trace.id))
        end
      end

      begin
        importer_pid = paused.pop(:timeout => 10)
        assert importer_pid, "import should pause after inserting the points"
        yield importer_pid
      ensure
        resume << true
        importer.join(10)
      end
    end
  end

  def with_lock_timeout
    Trace.with_connection { |c| c.execute("SET lock_timeout = '200ms'") }
    yield
  ensure
    Trace.with_connection { |c| c.execute("RESET lock_timeout") }
  end

  def blocked_by?(pid, blocker)
    Trace.with_connection do |c|
      c.select_value(Trace.sanitize_sql_array(["SELECT ? = ANY(pg_blocking_pids(?))", blocker, pid]))
    end
  end

  def wait_until(timeout: 10)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    sleep 0.01 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  end
end
