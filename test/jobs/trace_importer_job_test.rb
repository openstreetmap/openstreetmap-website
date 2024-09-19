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
      TraceImporterJob.perform_now(trace)
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
      TraceImporterJob.perform_now(trace)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)

    ActionMailer::Base.deliveries.clear
  end

  def test_error_notification
    # Check that the user gets a failure notification when something goes badly wrong
    trace = create(:trace)
    trace.stub(:import, -> { raise }) do
      TraceImporterJob.perform_now(trace)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_no_match(/Start tag expected/, email.text_part.body.to_s, "should not include parser error")
    assert_match(%r{jobs/trace_importer_job\.rb}, email.text_part.body.to_s, "should include stack backtrace")

    ActionMailer::Base.deliveries.clear
  end

  def test_parse_error_notification
    trace = create(:trace, :inserted => false, :fixture => "jpg")
    Rails.logger.silence do
      TraceImporterJob.perform_now(trace)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_match(/Start tag expected/, email.text_part.body.to_s, "should include parser error")
    assert_no_match(%r{jobs/trace_importer_job\.rb}, email.text_part.body.to_s, "should not include stack backtrace")

    ActionMailer::Base.deliveries.clear
  end

  def test_gz_parse_error_notification
    trace = create(:trace, :inserted => false, :fixture => "jpg.gz")
    Rails.logger.silence do
      TraceImporterJob.perform_now(trace)
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal trace.user.email, email.to[0]
    assert_match(/failure/, email.subject)
    assert_match(/Start tag expected/, email.text_part.body.to_s, "should include parser error")
    assert_no_match(%r{jobs/trace_importer_job\.rb}, email.text_part.body.to_s, "should not include stack backtrace")

    ActionMailer::Base.deliveries.clear
  end
end
