# frozen_string_literal: true

require "test_helper"

class BrowseTagChangesHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper
  include BrowseTagsHelper

  def test_format_tag_value_with_change_added
    change_info = { :type => :added, :current => "new_value" }
    html = format_tag_value_with_change("key", change_info)
    assert_dom_equal "<ins>new_value</ins>", html
  end

  def test_format_tag_value_with_change_unmodified
    change_info = { :type => :unmodified, :current => "value" }
    html = format_tag_value_with_change("key", change_info)
    assert_dom_equal "value", html
  end

  def test_format_tag_value_with_change_modified
    change_info = { :type => :modified, :current => "new_value", :previous => "old_value" }
    html = format_tag_value_with_change("key", change_info)
    assert_equal 2, html.length
    assert_dom_equal "<del>old_value</del>", html[0]
    assert_dom_equal "<ins>new_value</ins>", html[1]
  end

  def test_format_tag_value_with_change_removed
    change_info = { :type => :removed, :previous => "old_value" }
    html = format_tag_value_with_change("key", change_info)
    assert_dom_equal "<del>old_value</del>", html
  end

  def test_format_tag_value_with_change_nil
    change_info = { :type => nil, :current => "value" }
    html = format_tag_value_with_change("key", change_info)
    assert_dom_equal "value", html
  end
end
