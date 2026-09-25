# frozen_string_literal: true

require "test_helper"

class PaginationMethodsTest < ActiveSupport::TestCase
  include PaginationMethods

  test "#get_page_items can sort any records with compatible ids" do
    n1 = create(:changeset_comment_notification)
    n2 = create(:gpx_import_failure_notification)
    items = Noticed::Notification.all

    paged_items = get_page_items(items)

    assert_equal [n2, n1], paged_items.items
  end

  test "#get_page_items can sort records by an arbitrary column" do
    create(:user, :display_name => "Alba")
    create(:user, :display_name => "Calle")
    create(:user, :display_name => "Berhane")
    items = User.all

    paged_items = get_page_items(items, :cursor_column => :display_name)
    actual_names = paged_items.items.map(&:display_name)
    assert_equal %w[Calle Berhane Alba], actual_names
  end

  private

  #
  # Methods below are stubs for controller methods
  # that the PaginationMethods concern requires to work.
  #

  def param!(*)
    nil
  end

  def params
    {}
  end
end
