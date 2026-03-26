# frozen_string_literal: true

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

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/success/, email.subject)

    ActionMailer::Base.deliveries.clear
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

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)

    ActionMailer::Base.deliveries.clear
  end

  def test_error_notification
    # Check that the user gets a failure notification when something goes badly wrong
    trace = create(:trace)
    trace.stub(:import, -> { raise "Test Exception" }) do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_match(/Test Exception/, email.text_part.body.to_s, "should show the exception message")
    assert_exception_backtrace(email)

    ActionMailer::Base.deliveries.clear
  end

  def test_parse_error_notification
    trace = create(:trace, :inserted => false, :fixture => "jpg")
    Rails.logger.silence do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_match(/Fatal error:/, email.text_part.body.to_s, "should include parser error")
    assert_no_exception_backtrace(email)

    ActionMailer::Base.deliveries.clear
  end

  def test_gz_parse_error_notification
    trace = create(:trace, :inserted => false, :fixture => "jpg.gz")
    Rails.logger.silence do
      perform_enqueued_jobs do
        TraceImporterJob.perform_now(trace)
      end
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_match(/Fatal error:/, email.text_part.body.to_s, "should include parser error")
    assert_no_exception_backtrace(email)

    ActionMailer::Base.deliveries.clear
  end

  private

  def exception_backtrace_matcher
    %r{jobs/trace_importer_job\.rb}
  end

  def assert_exception_backtrace(email)
    assert_match(exception_backtrace_matcher, email.text_part.body.to_s, "should include stack backtrace")
  end

  def assert_no_exception_backtrace(email)
    assert_no_match(exception_backtrace_matcher, email.text_part.body.to_s, "should not include stack backtrace")
  end
end
