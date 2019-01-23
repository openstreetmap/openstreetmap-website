require "test_helper"
require "minitest/mock"

class TraceImporterJobTest < ActiveJob::TestCase
  def test_success_notification
    # Check that the user gets a success notification when the trace has valid points
    trace = create(:trace)

    gpx = Minitest::Mock.new
    def gpx.actual_points
      5
    end

    trace.stub(:import, gpx) do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    assert_performed_jobs 1

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/success/, email.subject)
  end

  def test_failure_notification
    # Check that the user gets a failure notification when the trace has no valid points
    trace = create(:trace)

    gpx = Minitest::Mock.new
    def gpx.actual_points
      0
    end

    trace.stub(:import, gpx) do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    assert_performed_jobs 1

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
  end

  def test_error_notification
    # Check that the user gets a failure notification when something goes badly wrong
    trace = create(:trace)
    trace.stub(:import, -> { raise }) do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    assert_performed_jobs 1

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
  end
end
