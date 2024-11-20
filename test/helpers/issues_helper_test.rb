require "test_helper"

class IssuesHelperTest < ActionView::TestCase
  attr_accessor :current_user

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
