# frozen_string_literal: true

require "test_helper"

class NumberedPaginationHelperTest < ActionView::TestCase
  def test_numbered_pagination1
    pagination = numbered_pagination(1, "active_page") { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 1 do
      assert_dom "> li", 1 do
        check_page_link sample_item_data(1)
      end
    end
  end

  def test_numbered_pagination1_active1
    pagination = numbered_pagination(1, "active_page", :active_page => 1) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 1 do
      assert_dom "> li", 1 do
        check_page_link sample_item_data(1), :active => true
      end
    end
  end

  def test_numbered_pagination5
    pagination = numbered_pagination(5, "active_page") { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 1 do
      assert_dom "> li", 5 do |items|
        items.each_with_index do |item, i|
          check_page_link item, sample_item_data(i + 1)
        end
      end
    end
  end

  def test_numbered_pagination6
    pagination = numbered_pagination(6, "active_page") { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do
        check_page_link sample_item_data(1)
      end
      assert_dom lists[1], "> li", 4 do |items|
        items.each_with_index do |item, i|
          check_page_link item, sample_item_data(i + 2)
        end
      end
      assert_dom lists[2], "> li", 1 do
        check_page_link sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active1
    pagination = numbered_pagination(6, "active_page", :active_page => 1) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 2 do |items|
        check_page_link items.shift, sample_item_data(1), :active => true
        check_page_link items.shift, sample_item_data(2)
      end
      assert_dom lists[1], "> li", 3 do |items|
        check_page_link items.shift, sample_item_data(3)
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active2
    pagination = numbered_pagination(6, "active_page", :active_page => 2) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 3 do |items|
        check_page_link items.shift, sample_item_data(1)
        check_page_link items.shift, sample_item_data(2), :active => true
        check_page_link items.shift, sample_item_data(3)
      end
      assert_dom lists[1], "> li", 2 do |items|
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active3
    pagination = numbered_pagination(6, "active_page", :active_page => 3) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 4 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3), :active => true
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active4
    pagination = numbered_pagination(6, "active_page", :active_page => 4) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 4 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3)
        check_page_link items.shift, sample_item_data(4), :active => true
        check_page_link items.shift, sample_item_data(5)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active5
    pagination = numbered_pagination(6, "active_page", :active_page => 5) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 2 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3)
      end
      assert_dom lists[2], "> li", 3 do |items|
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5), :active => true
        check_page_link items.shift, sample_item_data(6)
      end
    end
  end

  def test_numbered_pagination6_active6
    pagination = numbered_pagination(6, "active_page", :active_page => 6) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 3 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3)
        check_page_link items.shift, sample_item_data(4)
      end
      assert_dom lists[2], "> li", 2 do |items|
        check_page_link items.shift, sample_item_data(5)
        check_page_link items.shift, sample_item_data(6), :active => true
      end
    end
  end

  def test_numbered_pagination_window_start_include
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3, :active_page => 3) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 6 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3), :active => true
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5)
        check_page_link items.shift, sample_item_data(6)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_window_start_touch
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3, :active_page => 5) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 8 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3)
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5), :active => true
        check_page_link items.shift, sample_item_data(6)
        check_page_link items.shift, sample_item_data(7)
        check_page_link items.shift, sample_item_data(8)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_window_start_touch_almost
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3, :active_page => 6) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 9 do |items|
        check_page_link items.shift, sample_item_data(2)
        check_page_link items.shift, sample_item_data(3)
        check_page_link items.shift, sample_item_data(4)
        check_page_link items.shift, sample_item_data(5)
        check_page_link items.shift, sample_item_data(6), :active => true
        check_page_link items.shift, sample_item_data(7)
        check_page_link items.shift, sample_item_data(8)
        check_page_link items.shift, sample_item_data(9)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_window_middle
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3, :active_page => 43) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 9 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(40)
        check_page_link items.shift, sample_item_data(41)
        check_page_link items.shift, sample_item_data(42)
        check_page_link items.shift, sample_item_data(43), :active => true
        check_page_link items.shift, sample_item_data(44)
        check_page_link items.shift, sample_item_data(45)
        check_page_link items.shift, sample_item_data(46)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_window_end_touch
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3, :active_page => 46) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 8 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(43)
        check_page_link items.shift, sample_item_data(44)
        check_page_link items.shift, sample_item_data(45)
        check_page_link items.shift, sample_item_data(46), :active => true
        check_page_link items.shift, sample_item_data(47)
        check_page_link items.shift, sample_item_data(48)
        check_page_link items.shift, sample_item_data(49)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_window_end_beyond
    pagination = numbered_pagination(50, "active_page", :window_half_size => 3) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 3 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(48)
        check_page_link items.shift, sample_item_data(49)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(50)
      end
    end
  end

  def test_numbered_pagination_step
    pagination = numbered_pagination(35, "active_page", :step_size => 10, :window_half_size => 0) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 7 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(10)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(20)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(30)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(35)
      end
    end
  end

  def test_numbered_pagination_step_end_touch
    pagination = numbered_pagination(31, "active_page", :step_size => 10, :window_half_size => 0) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 6 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(10)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(20)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(30)
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(31)
      end
    end
  end

  def test_numbered_pagination_step_window
    pagination = numbered_pagination(35, "active_page", :active_page => 15, :step_size => 10, :window_half_size => 1) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 11 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(10)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(14)
        check_page_link items.shift, sample_item_data(15), :active => true
        check_page_link items.shift, sample_item_data(16)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(20)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(30)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(35)
      end
    end
  end

  def test_numbered_pagination_step_window_touch
    pagination = numbered_pagination(35, "active_page", :active_page => 12, :step_size => 10, :window_half_size => 1) { |n| sample_item_data n }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 3 do |lists|
      assert_dom lists[0], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(1)
      end
      assert_dom lists[1], "> li", 10 do |items|
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(10)
        check_page_link items.shift, sample_item_data(11)
        check_page_link items.shift, sample_item_data(12), :active => true
        check_page_link items.shift, sample_item_data(13)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(20)
        check_page_ellipsis items.shift
        check_page_link items.shift, sample_item_data(30)
        check_page_ellipsis items.shift
      end
      assert_dom lists[2], "> li", 1 do |items|
        check_page_link items.shift, sample_item_data(35)
      end
    end
  end

  private

  def sample_item_data(n)
    { :href => "test/version/#{n}", :title => "Version ##{n}" }
  end

  def check_page_link(*elements, data, active: false)
    assert_dom(*elements, "> @class", active ? "page-item active" : "page-item")
    assert_dom(*elements, "> a", 1) do
      assert_dom "> @href", data[:href]
      assert_dom "> @title", data[:title]
    end
  end

  def check_page_ellipsis(*elements)
    assert_dom(*elements, "> @class", "page-item disabled")
    assert_dom(*elements, "> a", 0)
    assert_dom(*elements, "> span", 1, "...")
  end
end
