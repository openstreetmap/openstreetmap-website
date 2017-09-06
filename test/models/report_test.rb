require "test_helper"

class ReportTest < ActiveSupport::TestCase
  def test_details_required
    report = create(:report)

    assert report.valid?
    report.details = ''
    assert !report.valid?
  end
end
