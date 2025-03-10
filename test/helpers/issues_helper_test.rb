require "test_helper"

class IssuesHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def test_reportable_dates_note
    note = create(:note, :created_at => "2020-03-14", :updated_at => "2021-05-16")

    dates = reportable_dates note

    dom_dates = Rails::Dom::Testing.html_document_fragment.parse "<p>#{dates}</p>"
    assert_dom dom_dates, ":root", "created on 14 March 2020 at 00:00, updated on 16 May 2021 at 00:00"
  end

  def test_reportable_dates_user
    user = create(:user, :created_at => "2020-07-18")

    dates = reportable_dates user

    dom_dates = Rails::Dom::Testing.html_document_fragment.parse "<p>#{dates}</p>"
    assert_dom dom_dates, ":root", "created on 18 July 2020 at 00:00"
  end

  def test_issues_count
    target_user = create(:user)
    self.current_user = create(:moderator_user)

    n = (Settings.max_issues_count - 1)
    n.times do
      create(:note_with_comments) do |note|
        create(:issue, :reportable => note, :reported_user => target_user, :assigned_role => "moderator")
      end
    end
    expected = <<~HTML.delete("\n")
      <span class="badge count-number">#{n}</span>
    HTML
    assert_dom_equal expected, open_issues_count

    n += 1
    create(:note_with_comments) do |note|
      create(:issue, :reportable => note, :reported_user => target_user, :assigned_role => "moderator")
    end
    expected = <<~HTML.delete("\n")
      <span class="badge count-number">#{n}+</span>
    HTML
    assert_dom_equal expected, open_issues_count
  end
end
