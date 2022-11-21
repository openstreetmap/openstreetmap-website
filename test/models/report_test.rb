require "test_helper"

class ReportTest < ActiveSupport::TestCase
  def test_issue_required
    report = create(:report)

    assert_predicate report, :valid?
    report.issue = nil
    assert_not report.valid?
  end

  def test_user_required
    report = create(:report)

    assert_predicate report, :valid?
    report.user = nil
    assert_not report.valid?
  end

  def test_details_required
    report = create(:report)

    assert_predicate report, :valid?
    report.details = ""
    assert_not report.valid?
  end

  def test_category_required
    report = create(:report)

    assert_predicate report, :valid?
    report.category = ""
    assert_not report.valid?
  end

  def test_details
    report = create(:report)
    assert_instance_of(RichText::Markdown, report.details)
  end
end
