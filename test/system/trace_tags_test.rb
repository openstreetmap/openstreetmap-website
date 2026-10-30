# frozen_string_literal: true

require "application_system_test_case"

class TraceTagsTest < ApplicationSystemTestCase
  test "shows the tags a new trace will get" do
    sign_in_as(create(:user))
    visit new_trace_path

    fill_in "Tags", :with => "foo bar"
    assert_tags "foo", "bar"

    fill_in "Tags", :with => "foo bar, baz"
    assert_tags "foo bar", "baz"
  end

  test "shows the tags of a trace being edited" do
    trace = create(:trace, :fixture => "a")
    create(:tracetag, :trace => trace, :tag => "foo bar")
    create(:tracetag, :trace => trace, :tag => "baz")

    sign_in_as(trace.user)
    visit edit_trace_path(trace)
    assert_tags "foo bar", "baz"

    fill_in "Tags", :with => "foo bar baz"
    assert_tags "foo", "bar", "baz"
  end

  private

  def assert_tags(*names)
    names.each do |name|
      assert_css "li.badge", :exact_text => name
    end
    assert_css "li.badge", :count => names.size
  end
end
