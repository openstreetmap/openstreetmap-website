require "test_helper"

class ReportTest < ActiveSupport::TestCase
  def test_issue_required
    report = create(:report)

    assert report.valid?
    report.issue = nil
    assert !report.valid?
  end

  def test_user_required
    report = create(:report)

    assert report.valid?
    report.user = nil
    assert !report.valid?
  end

  def test_details_required
    report = create(:report)

    assert report.valid?
    report.details = ""
    assert !report.valid?
  end

  def test_category_required
    report = create(:report)

    assert report.valid?
    report.category = ""
    assert !report.valid?
  end
end
