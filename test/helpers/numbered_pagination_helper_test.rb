require "test_helper"

class NumberedPaginationHelperTest < ActionView::TestCase
  def test_element_versions_pagination1
    pagination = element_versions_pagination(1) { |v| sample_item_data v }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 1 do
      assert_dom "> li", 1 do
        check_version_link sample_item_data(1)
      end
    end
  end

  def test_element_versions_pagination5
    pagination = element_versions_pagination(5) { |v| sample_item_data v }
    pagination_dom = Rails::Dom::Testing.html_document_fragment.parse(pagination)
    assert_dom pagination_dom, "ul", :count => 1 do
      assert_dom "> li", 5 do |items|
        items.each_with_index do |item, i|
          check_version_link item, sample_item_data(i + 1)
        end
      end
    end
  end

  private

  def sample_item_data(version)
    { :href => "test/version/#{version}", :title => "Version ##{version}" }
  end

  def check_version_link(*elements, data)
    assert_dom(*elements, "> a", 1) do
      assert_dom "> @href", data[:href]
      assert_dom "> @title", data[:title]
    end
  end
end
